/* Youngest vs Oldest user counts per gender (sign-ups between 2019-01-01 and 2022-04-30) */
WITH bounds AS (          -- youngest (min_age) & oldest (max_age) per gender
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE "gender" IN ('F','M')
      AND "created_at" BETWEEN 1546300800000000   -- 2019-01-01 00:00:00 UTC
                         AND 1651363199000000     -- 2022-04-30 23:59:59 UTC
    GROUP BY "gender"
),
youngest AS (             -- count users whose age = gender’s min_age
    SELECT
        u."gender",
        COUNT(*) AS "youngest_cnt"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" u
    JOIN bounds b
      ON u."gender" = b."gender"
     AND u."age"    = b."min_age"
    WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY u."gender"
),
oldest AS (               -- count users whose age = gender’s max_age
    SELECT
        u."gender",
        COUNT(*) AS "oldest_cnt"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" u
    JOIN bounds b
      ON u."gender" = b."gender"
     AND u."age"    = b."max_age"
    WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY u."gender"
)
SELECT
    b."gender",
    b."min_age"  AS "youngest_age",
    y."youngest_cnt",
    b."max_age"  AS "oldest_age",
    o."oldest_cnt"
FROM bounds  b
LEFT JOIN youngest y ON b."gender" = y."gender"
LEFT JOIN oldest   o ON b."gender" = o."gender"
ORDER BY b."gender";