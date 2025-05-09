WITH filtered_users AS (
    SELECT 
        "id",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) BETWEEN '2019-01-01' AND '2022-04-30'
),
age_extremes AS (
    SELECT 
        MAX("age") AS max_age,
        MIN("age") AS min_age
    FROM filtered_users
),
age_counts AS (
    SELECT
        (SELECT COUNT(*) FROM filtered_users fu JOIN age_extremes ae ON fu."age" = ae.max_age) AS max_age_count,
        (SELECT COUNT(*) FROM filtered_users fu JOIN age_extremes ae ON fu."age" = ae.min_age) AS min_age_count
)
SELECT 
    max_age_count - min_age_count AS "difference_in_user_counts"
FROM age_counts;