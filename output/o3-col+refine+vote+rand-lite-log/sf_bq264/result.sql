WITH registrants AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000   -- 01-Jan-2019 00:00:00
                          AND 1651363199000000   -- 30-Apr-2022 23:59:59
), 
age_bounds AS (
    SELECT 
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM registrants
), 
age_counts AS (
    SELECT
        SUM(CASE WHEN r."age" = ab.youngest_age THEN 1 ELSE 0 END) AS youngest_cnt,
        SUM(CASE WHEN r."age" = ab.oldest_age   THEN 1 ELSE 0 END) AS oldest_cnt
    FROM registrants r
    CROSS JOIN age_bounds ab
)
SELECT 
       (oldest_cnt - youngest_cnt) AS "difference_in_user_counts"
FROM age_counts;