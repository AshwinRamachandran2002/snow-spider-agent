WITH cohort AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651276800000000
),
extremes AS (
    SELECT 
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM cohort
),
counts AS (
    SELECT
        (SELECT COUNT(*) FROM cohort WHERE "age" = (SELECT "youngest_age" FROM extremes)) AS "youngest_user_count",
        (SELECT COUNT(*) FROM cohort WHERE "age" = (SELECT "oldest_age" FROM extremes))  AS "oldest_user_count"
)
SELECT 
    "oldest_user_count" - "youngest_user_count" AS "difference_oldest_vs_youngest"
FROM counts;