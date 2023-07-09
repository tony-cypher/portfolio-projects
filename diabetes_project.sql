-- This is a dataset from Kaggle for diabetes Test

-- Skills: comparison, opeartions, aggregate, join, union, subqueries, exists, views, function, trigger, case, if window functions,cte

SELECT * FROM diabetes
LIMIT 100;

-- 7461 patients have hypertension
SELECT * FROM diabetes
WHERE hypertension > 0;

-- 
-- 88685 patients does not have hypertension
SELECT * FROM diabetes
WHERE hypertension = 0;

-- 915 patients have both hypertension and heart_disease
SELECT * FROM diabetes 
WHERE hypertension = 1 AND heart_disease = 1;

-- 8482 patients have diabetes and average bmi of 32 (obese)
SELECT ROUND(AVG(bmi),2) as avg_bmi, COUNT(bmi) no_of_patients
FROM diabetes
WHERE diabetes = 1;

# 87664 patients don't have diabetes and average bmi of 26.87
SELECT ROUND(AVG(bmi),2) as avg_bmi, COUNT(bmi) no_of_patients
FROM diabetes
WHERE diabetes = 0;

SELECT * FROM diabetes
WHERE bmi > 90;


SELECT 
	gender, diabetes, COUNT(diabetes) count
FROM diabetes
GROUP BY gender, diabetes
ORDER BY gender, diabetes; 


CREATE OR REPLACE VIEW v_avg_diabetes_glucose AS
	SELECT diabetes, ROUND(AVG(blood_glucose_level),3) AS avg_glucose 
    FROM diabetes
    GROUP BY diabetes;

SELECT * FROM v_avg_diabetes_glucose;


DROP PROCEDURE IF EXISTS p_avg_diabetes_heart;

DELIMITER $$
CREATE PROCEDURE p_avg_diabetes_heart(IN p_diabetes INT, IN p_heart_disease INT, OUT p_avg_age INT)
BEGIN
	SELECT
		ROUND(AVG(age)) INTO p_avg_age
	FROM diabetes
    WHERE diabetes = 1 AND blood_glucose_level > 140;
END $$
DELIMITER ;

SET @avg_age = 0;
CALL diabetes.p_avg_diabetes_heart(1, 0, @avg_age);
SELECT @avg_age;


SELECT * FROM diabetes
Limit 100;

DELIMITER $$
CREATE FUNCTION f_smoking_diabetes (p_smoke VARCHAR(50)) RETURNS INT
DETERMINISTIC
BEGIN
	
    DECLARE v_no_diabetes INT;
    
    SELECT 
		COUNT(diabetes) INTO v_no_diabetes
	FROM 
		diabetes
	WHERE
		smoking_history = p_smoke;
	RETURN v_no_diabetes;
END $$
DELIMITER ;

SELECT f_smoking_diabetes('no info');

SELECT * FROM diabetes;


-- set the value of diabetes to 0 for any wrong value
DELIMITER $$

CREATE TRIGGER before_diabetes_insert
BEFORE INSERT ON diabetes
FOR EACH ROW 
BEGIN
	IF (NEW.diabetes != 1) OR (NEW.diabetes != 0) THEN
		SET NEW.diabetes = 0;
	END IF;
END $$
DELIMITER ;

SELECT 
	gender, age, smoking_history,
    CASE 
		WHEN age > 60 THEN 'Old'
        WHEN (age < 60) AND (age > 30) THEN 'Middle Aged'
        ELSE 'Young'
	END AS aged
FROM diabetes;

SELECT
	gender, age, smoking_history, IF(age > 50, 'Old', 'Young') aged
FROM diabetes;

SELECT * FROM diabetes;

SELECT 
	age, smoking_history, blood_glucose_level, diabetes, ROW_NUMBER () OVER w AS glucose_rank
FROM diabetes
WINDOW w AS (PARTITION BY smoking_history ORDER BY blood_glucose_level DESC);

CREATE TEMPORARY TABLE glucose_level
SELECT * FROM diabetes
WHERE blood_glucose_level > 200
ORDER BY blood_glucose_level;

CREATE TEMPORARY TABLE  HbA1c_level
SELECT * FROM diabetes
WHERE HbA1c_level > 6.6
ORDER BY HbA1c_level;

SELECT * FROM glucose_level;
SELECT * FROM HbA1c_level;

-- FROM THIS ANALYSIS WE CAN OBSERVE THAT ANY PATIENT WITH blood_glucose_level > 200 or 
-- HbA1c_level > 6.6 HAVE DIABETES. 