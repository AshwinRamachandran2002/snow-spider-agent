WITH filtered_users AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_TIMESTAMP_NTZ("created_at" / 1000000) >= '2019-01-01'
      AND TO_TIMESTAMP_NTZ("created_at" / 1000000) <= '2022-04-30 23:59:59'
),
age_bounds AS (
    SELECT 
        MAX("age") AS max_age,
        MIN("age") AS min_age
    FROM filtered_users
),
age_counts AS (
    SELECT
        (SELECT COUNT(*) FROM filtered_users fu, age_bounds ab WHERE fu."age" = ab.max_age) AS oldest_count,
        (SELECT COUNT(*) FROM filtered_users fu, age_bounds ab WHERE fu."age" = ab.min_age) AS youngest_count
)
SELECT 
    ABS(oldest_count - youngest_count) AS "difference_in_number"
FROM age_counts;