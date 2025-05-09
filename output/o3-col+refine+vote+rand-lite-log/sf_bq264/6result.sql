WITH "users_in_range" AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651276800000000
),
"age_bounds" AS (
    SELECT
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM "users_in_range"
),
"age_counts" AS (
    SELECT
        (SELECT COUNT(*) FROM "users_in_range" WHERE "age" = (SELECT "max_age" FROM "age_bounds")) AS "cnt_oldest",
        (SELECT COUNT(*) FROM "users_in_range" WHERE "age" = (SELECT "min_age" FROM "age_bounds")) AS "cnt_youngest"
)
SELECT
    "cnt_oldest" - "cnt_youngest" AS "difference_oldest_vs_youngest"
FROM "age_counts";