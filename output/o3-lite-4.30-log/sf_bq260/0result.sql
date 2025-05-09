WITH "bounds" AS (
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY "gender"
), "youngest_users" AS (
    SELECT
        u."gender",
        'youngest' AS "age_type",
        COUNT(*) AS "user_count"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
    JOIN "bounds" b
      ON u."gender" = b."gender"
     AND u."age"    = b."min_age"
    WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY u."gender"
), "oldest_users" AS (
    SELECT
        u."gender",
        'oldest'  AS "age_type",
        COUNT(*)  AS "user_count"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
    JOIN "bounds" b
      ON u."gender" = b."gender"
     AND u."age"    = b."max_age"
    WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY u."gender"
)
SELECT * FROM "youngest_users"
UNION ALL
SELECT * FROM "oldest_users"
ORDER BY "gender" ASC, "age_type" ASC;