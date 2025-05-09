/* Youngest & oldest user counts by gender for sign-ups between 2019-01-01 and 2022-04-30 */

WITH "user_in_period" AS (   -- filter to the required sign-up window
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000      -- 2019-01-01 00:00:00 (µs)
                          AND 1651363199000000       -- 2022-04-30 23:59:59 (µs)
),

/* find the min & max ages for each gender */
"age_bounds" AS (
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM "user_in_period"
    GROUP BY "gender"
),

/* count users who are at the minimum age */
"youngest_cnt" AS (
    SELECT
        u."gender",
        COUNT(*) AS "youngest_user_cnt"
    FROM "user_in_period" u
    JOIN "age_bounds" b
      ON u."gender" = b."gender"
     AND u."age"    = b."min_age"
    GROUP BY u."gender"
),

/* count users who are at the maximum age */
"oldest_cnt" AS (
    SELECT
        u."gender",
        COUNT(*) AS "oldest_user_cnt"
    FROM "user_in_period" u
    JOIN "age_bounds" b
      ON u."gender" = b."gender"
     AND u."age"    = b."max_age"
    GROUP BY u."gender"
)

/* assemble final result */
SELECT
    b."gender",
    b."min_age",        -- youngest age
    y."youngest_user_cnt",
    b."max_age",        -- oldest age
    o."oldest_user_cnt"
FROM "age_bounds" b
LEFT JOIN "youngest_cnt" y USING ("gender")
LEFT JOIN "oldest_cnt"   o USING ("gender")
ORDER BY b."gender";