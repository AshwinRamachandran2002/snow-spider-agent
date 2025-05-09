/* Youngest vs Oldest users per gender for sign‑ups between 2019‑01‑01 and 2022‑04‑30 */
WITH filtered_users AS (   -- keep only users in the requested time window
    SELECT "gender",
           "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000     -- 2019‑01‑01
                          AND 1651363200000000      -- 2022‑04‑30
),
age_bounds AS (            -- find the minimum and maximum age per gender
    SELECT "gender",
           MIN("age") AS "min_age",
           MAX("age") AS "max_age"
    FROM filtered_users
    GROUP BY "gender"
),
extreme_counts AS (        -- count how many users are at each extreme
    SELECT  f."gender",
            SUM(CASE WHEN f."age" = b."min_age" THEN 1 ELSE 0 END) AS "youngest_user_count",
            SUM(CASE WHEN f."age" = b."max_age" THEN 1 ELSE 0 END) AS "oldest_user_count"
    FROM    filtered_users f
    JOIN    age_bounds     b ON f."gender" = b."gender"
    GROUP BY f."gender"
)
SELECT  e."gender",
        b."min_age",
        e."youngest_user_count",
        b."max_age",
        e."oldest_user_count"
FROM    extreme_counts e
JOIN    age_bounds   b ON e."gender" = b."gender"
ORDER BY e."gender";