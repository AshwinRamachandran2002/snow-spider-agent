WITH user_pool AS (
    SELECT 
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_TIMESTAMP("created_at"/1000000) 
          BETWEEN '2019-01-01 00:00:00' AND '2022-04-30 23:59:59'
), age_bounds AS (
    SELECT 
        MAX("age") AS oldest_age,
        MIN("age") AS youngest_age
    FROM user_pool
), age_counts AS (
    SELECT
        SUM(CASE WHEN up."age" = ab.oldest_age   THEN 1 ELSE 0 END) AS oldest_users,
        SUM(CASE WHEN up."age" = ab.youngest_age THEN 1 ELSE 0 END) AS youngest_users
    FROM user_pool up
    CROSS JOIN age_bounds ab
)
SELECT 
    oldest_users,
    youngest_users,
    ABS(oldest_users - youngest_users) AS difference_in_number
FROM age_counts;