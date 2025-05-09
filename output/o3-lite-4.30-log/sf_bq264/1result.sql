WITH age_bounds AS (
    SELECT
        MAX("age") AS max_age,
        MIN("age") AS min_age
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651276800000000
),
age_counts AS (
    SELECT
        COUNT_IF("age" = max_age) AS oldest_users,
        COUNT_IF("age" = min_age) AS youngest_users
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS", age_bounds
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651276800000000
)
SELECT ABS(oldest_users - youngest_users) AS users_difference
FROM age_counts;