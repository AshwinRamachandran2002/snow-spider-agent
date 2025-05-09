WITH filtered_users AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE DATE(TO_TIMESTAMP("created_at" / 1000000)) BETWEEN '2019-01-01' AND '2022-04-30'
),
age_extremes AS (
    SELECT 
        MAX("age") AS oldest_age,
        MIN("age") AS youngest_age
    FROM filtered_users
)
SELECT
    COUNT_IF("age" = (SELECT oldest_age FROM age_extremes))
  - COUNT_IF("age" = (SELECT youngest_age FROM age_extremes))  AS difference_oldest_vs_youngest
FROM filtered_users;