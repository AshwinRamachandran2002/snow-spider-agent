WITH filtered_users AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE TO_TIMESTAMP_NTZ("created_at" / 1000000) BETWEEN '2019-01-01' AND '2022-04-30'
),
age_limits AS (
    SELECT
        MAX("age") AS max_age,
        MIN("age") AS min_age
    FROM filtered_users
),
age_group_counts AS (
    SELECT
        SUM(CASE WHEN fu."age" = al.max_age THEN 1 ELSE 0 END) AS oldest_user_count,
        SUM(CASE WHEN fu."age" = al.min_age THEN 1 ELSE 0 END) AS youngest_user_count
    FROM filtered_users fu
    CROSS JOIN age_limits al
)
SELECT
    ABS(oldest_user_count - youngest_user_count) AS difference_in_count_between_oldest_and_youngest_users
FROM age_group_counts;