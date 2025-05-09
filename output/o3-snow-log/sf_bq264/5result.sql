WITH filtered_users AS (
    SELECT 
        "id",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_TIMESTAMP("created_at" / 1000000) BETWEEN '2019-01-01' AND '2022-04-30'
),
age_extremes AS (
    SELECT 
        MAX("age") AS oldest_age,
        MIN("age") AS youngest_age
    FROM filtered_users
),
age_counts AS (
    SELECT
        (SELECT COUNT(*) FROM filtered_users fu, age_extremes ae WHERE fu."age" = ae.oldest_age)   AS oldest_user_count,
        (SELECT COUNT(*) FROM filtered_users fu, age_extremes ae WHERE fu."age" = ae.youngest_age) AS youngest_user_count
)
SELECT 
    ABS(oldest_user_count - youngest_user_count) AS difference_in_number
FROM age_counts;