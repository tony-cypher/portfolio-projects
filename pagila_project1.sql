# This a data from Kaggle https://www.kaggle.com/datasets/kapturovalexander/pagila-postgresql-sample-database
# Aim of this project is using different SQL queries to anayse and show useful insights in the data
# The original data in Kaggle contains 15 csv files (15 tables)
# I used pandas, numpy (python) to change the data into tuple to be able to insert them in their respective tables in the database
# Queries used: agg, ifnull, coalesce, joins, subqueries, unions, views, procedures, functions, case, window function, cte

USE pagila;

#------  Most common districts  -------#
SELECT 
	district, COUNT(district) no_of_district
FROM 
	address
GROUP BY district
HAVING no_of_district > 5
ORDER BY no_of_district DESC;

#-------  Number of movies with their respective ratings  ------#
SELECT 
	rating, COUNT(rating) no_of_rating
FROM 
	film
GROUP BY rating
ORDER BY no_of_rating DESC;

#-------  address, showing N/A where there is no postal_code or phone  -------#
SELECT 
	address_id, district, city_id,
    IFNULL(postal_code, 'N/A') AS postal_code,
    COALESCE(phone, 'N/A') AS phone
FROM address;

#------- customer info with all movies they rented, including rating and return date  -------#
SELECT 
	c.customer_id, c.first_name, c.last_name, c.email,
    f.title, f.rating, COALESCE(r.return_date, 'N/A') AS return_date
FROM
	customer c 
		JOIN
	rental r ON c.customer_id = r.customer_id
		JOIN
	inventory i ON r.inventory_id = i.inventory_id
		JOIN
	film f ON i.film_id = f.film_id
WHERE f.rating = 'R'
ORDER BY c.customer_id, f.title;

#------- This query selects all the customers and shows the number of movies they collected under each staff(2) 
#------- and assigning the staffs as supervisor of the movies collected under them.  
SELECT
	customer_id, COUNT(customer_id) AS no_of_movies,
    (SELECT
		staff_id
	FROM staff
    WHERE staff_id =1) AS supervisor
FROM
	rental
GROUP BY customer_id, staff_id
ORDER BY customer_id;
SELECT 
	A.*
FROM
	(SELECT
		customer_id, COUNT(customer_id) AS no_of_movies,
		(SELECT
			staff_id
		FROM staff
		WHERE staff_id =1) AS supervisor
	FROM
		rental
	WHERE staff_id = 1
	GROUP BY customer_id, staff_id
	ORDER BY customer_id) AS A
UNION ALL
SELECT
	B.*
FROM
	(SELECT
		customer_id, COUNT(customer_id) AS no_of_movies,
		(SELECT
			staff_id
		FROM staff
		WHERE staff_id =2) AS supervisor
	FROM
		rental
	WHERE staff_id = 2
	GROUP BY customer_id, staff_id
	ORDER BY customer_id) AS B;

#------- creating view that stores customer's payment id, amount for renting the movie, rental and return date  ------#
CREATE OR REPLACE VIEW v_amount_rental_return_date AS
	SELECT 
		payment_id, p.customer_id, p.staff_id, p.amount, r.rental_date, r.return_date
	FROM
		payment p 
			JOIN
		rental r ON p.rental_id = r.rental_id
	ORDER BY p.customer_id;

SELECT * FROM v_amount_rental_return_date;

#-------  procedure that displays all movies a customer rented and their rating, taking the customer_id as input  -------#
DROP PROCEDURE IF EXISTS p_customer_movie;

DELIMITER $$
CREATE PROCEDURE p_customer_movie(IN p_customer_id INT)
BEGIN
	SELECT 
		f.title, f.rating
	FROM 
		rental r
			JOIN 
		inventory i ON r.inventory_id = i.inventory_id
			JOIN 
		film f ON i.film_id = f.film_id
	WHERE r.customer_id = p_customer_id
	ORDER BY f.rating;
END $$
DELIMITER ;

call pagila.p_customer_movie(19);

#-------  function that returns the customer's country, taking the customer_id as input  --------#
DROP FUNCTION IF EXISTS f_customer_country;

DELIMITER $$
CREATE FUNCTION f_customer_country(f_customer_id INTEGER) RETURNS CHAR(50)
DETERMINISTIC
BEGIN
DECLARE v_country CHAR(50);

SELECT 
	c2.country INTO v_country
FROM
	customer c
		JOIN
	address a ON c.address_id = a.address_id
		JOIN
	city c1 ON a.city_id = c1.city_id
		JOIN
	country c2 ON c1.country_id = c2.country_id
WHERE 
	c.customer_id = f_customer_id;
RETURN v_country;
END $$
DELIMITER ;

SELECT f_customer_country(50);

#-------  All movies and the meaning of their rating respectively  ------#
SELECT 
	film_id, title,
    CASE
		WHEN rating = 'PG' THEN 'Parental Guidance for Children'
        WHEN rating = 'NC-17' THEN '18+ Only'
        WHEN rating = 'R' THEN 'Parental Guidance for Under 17'
        WHEN rating = 'G' THEN 'All Ages'
        ELSE 'Parental Guidance for Under 13'
	END AS rating
FROM 
	film;

#-------  actors and the number of movies they were involved in accordingly  -------#
SELECT
	fa.actor_id, f.title,
    ROW_NUMBER () OVER w AS movie_number
FROM
	film_actor fa
		JOIN
	film f ON fa.film_id = f.film_id
WINDOW w AS (PARTITION BY fa.actor_id ORDER BY f.title);

#-------  This shows previous and next movie taken by each customer  -------#
SELECT 
	customer_id, title, rental_date, return_date,
    LAG(title) OVER w AS previous_movie,
    LEAD(title) OVER w AS next_movie
FROM 
	rental r
		JOIN
	inventory i ON r.inventory_id = i.inventory_id
		JOIN
	film f ON i.film_id = f.film_id
WINDOW w AS (PARTITION BY customer_id ORDER BY rental_date);

#-------  actors with above average(27) movie involvement, and below  ------#
WITH cte1 AS (
SELECT 
	ROUND(AVG(A.movies_involved)) avg_actors
FROM
	(SELECT 
		actor_id, COUNT(film_id) movies_involved
	FROM
		film_actor
	GROUP BY actor_id) A),
cte2 AS (SELECT 
	actor_id, COUNT(film_id) movies_involved
FROM
	film_actor
GROUP BY actor_id)
SELECT
	 SUM(CASE WHEN c2.movies_involved >= c1.avg_actors THEN 1 ELSE 0 END) AS actors_above_avg_contribution,
     SUM(CASE WHEN c2.movies_involved < c1.avg_actors THEN 1 ELSE 0 END) AS actors_below_avg_contribution,
     (SELECT COUNT(actor_id) FROM actor) AS total_actors
FROM
	cte2 c2
		CROSS JOIN 
	cte1 c1;