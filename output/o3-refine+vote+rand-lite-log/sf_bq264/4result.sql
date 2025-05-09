WITH filtered_users AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) 
          BETWEEN '2019-01-01' AND '2022-04-30'
), age_bounds AS (
    SELECT MAX("age") AS max_age,
           MIN("age") AS min_age
    FROM filtered_users
), age_counts AS (
    SELECT
        SUM(CASE WHEN fu."age" = ab.max_age THEN 1 ELSE 0 END) AS oldest_users,
        SUM(CASE WHEN fu."age" = ab.min_age THEN 1 ELSE 0 END) AS youngest_users
    FROM filtered_users fu
    CROSS JOIN age_bounds ab
)
SELECT ABS(oldest_users - youngest_users) AS "difference_in_number"
FROM age_counts;