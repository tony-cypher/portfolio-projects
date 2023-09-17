# ----------------  Life Resturant DATABASE    ----------------------#
# ----------------  Application of CTEs, JOINs, and Windows Operation to solve problems  ------#

-- 1. What is the total amount each customer spent at the resturant?

SELECT
	s.customer_id, SUM(m.price) total_amount
FROM 
	sales s
		JOIN
	menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;


-- 2. How many days has each customer visited the resturant?

SELECT 
	customer_id, COUNT(DISTINCT(order_date)) AS no_of_days
FROM sales
GROUP BY customer_id;


-- 3. What is the first item from the menu purchased by each customer?

WITH first_sales AS
(
	SELECT 
		customer_id, product_name, 
        DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS ranks
	FROM
		sales s 
			JOIN
		menu m ON s.product_id = m.product_id)
SELECT 
	customer_id, product_name
FROM first_sales
WHERE ranks = 1
GROUP BY customer_id, product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all custommers?

SELECT
	s.product_id, product_name, COUNT(s.product_id) purchases
FROM
	sales s
		JOIN
	menu m ON s.product_id = m.product_id
GROUP BY s.product_id
ORDER BY purchases DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer

WITH product_count AS
(
	SELECT 
		s.customer_id, m.product_name, COUNT(s.product_id) AS counts,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS ranks
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY customer_id, s.product_id)

SELECT
	customer_id, product_name, counts
FROM product_count
WHERE ranks = 1;


-- 6. Which item was purchased first by the customer after they become a member?

WITH purchase_rank AS
(
SELECT 
	s.customer_id, product_id, order_date, join_date,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS ranks
FROM 
	sales s
		JOIN
	members m ON s.customer_id = m.customer_id
WHERE
	order_date >= join_date)
SELECT 
	p.customer_id, m.product_name, order_date, join_date
FROM 
	purchase_rank p 
		JOIN
	menu m ON p.product_id = m.product_id
WHERE ranks = 1;



-- 7. Which item was purchased just before the customer became a member?

WITH purchase_rank AS
(
SELECT
	s.customer_id, product_id, order_date, join_date,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS ranks
FROM 
	sales s 
		JOIN
	members m ON s.customer_id = m.customer_id
WHERE 
	join_date > order_date)

SELECT
	customer_id, m.product_name, order_date, join_date
FROM
	purchase_rank p 
		JOIN
	menu m ON p.product_id = m.product_id
WHERE ranks = 1
ORDER BY customer_id;


-- 8. What is the total item and amount spent for each member before they became a member?

SELECT 
	s.customer_id,
    COUNT(mu.product_name) AS product_count,
    SUM(price) AS total_amount
FROM 
	sales s 
		JOIN
	members m ON s.customer_id = m.customer_id
		JOIN
	menu mu ON s.product_id = mu.product_id
WHERE order_date < join_date
GROUP BY s.customer_id 
ORDER BY s.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier, 
--    how many points would each customer have?

WITH customer_points AS
(
SELECT 
	s.customer_id, m.product_name, price,
    IF(m.product_id = 1, price * 20, price * 10) AS points
FROM
	sales s 
		JOIN
	menu m ON s.product_id = m.product_id
    ORDER BY s.customer_id, m.product_name)
    
SELECT 
	customer_id, SUM(points) AS total_points
FROM customer_points
GROUP BY customer_id;


-- 10. In the first week after a customer joins the program (including their join date)
--     they earn 2x points on all items, not just sushi, how many points do customer A 
--     and B have at the end of january?

WITH start_bonus AS
(
SELECT 
	s.customer_id,product_name, order_date, join_date,
    DATE(DATE(join_date) +6) AS bonus_date, price
FROM 
	sales s 
		JOIN 
	members m ON s.customer_id = m.customer_id
		JOIN
	menu me ON s.product_id = me.product_id
ORDER BY s.customer_id),

with_bonus AS
(
SELECT customer_id, product_name, 
	IF(order_date >= join_date AND order_date <= bonus_date OR product_name = 'sushi', price *20 , price*10) AS points
FROM start_bonus
ORDER BY customer_id, order_date)

SELECT
	customer_id, SUM(points) AS total_points
FROM with_bonus
GROUP BY customer_id;
