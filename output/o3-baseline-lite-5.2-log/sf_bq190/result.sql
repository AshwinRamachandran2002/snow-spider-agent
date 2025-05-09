WITH filtered_users AS (
    SELECT
        "id",
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE
        TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) BETWEEN '2019-01-01' AND '2022-04-30'
        AND "gender" IN ('M', 'F')          -- keep only Male and Female
),
user_bounds AS (
    SELECT
        "id",
        "gender",
        "age",
        MIN("age") OVER (PARTITION BY "gender") AS min_age,
        MAX("age") OVER (PARTITION BY "gender") AS max_age
    FROM filtered_users
)
SELECT
    "gender",
    MIN(min_age)                         AS youngest_age,
    COUNT_IF("age" = min_age)            AS youngest_user_count,
    MAX(max_age)                         AS oldest_age,
    COUNT_IF("age" = max_age)            AS oldest_user_count
FROM user_bounds
GROUP BY "gender"
ORDER BY "gender";