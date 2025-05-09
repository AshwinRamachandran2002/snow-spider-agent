/* Determine youngest & oldest users (and their counts) 
   for each gender who registered between 2019-01-01
   and 2022-04-30 (inclusive of 04-30, exclusive of 05-01). */

WITH cohort AS (          -- users in the required sign-up window
    SELECT
        "id",
        "gender",
        "age"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE "created_at" >= 1546300800000000      -- 2019-01-01 00:00:00
      AND "created_at" <  1651363200000000      -- 2022-05-01 00:00:00
      AND "gender" IN ('M', 'F')                -- keep only M & F
),

age_extremes AS (         -- min & max age per gender
    SELECT
        "gender",
        MIN("age") AS min_age,
        MAX("age") AS max_age
    FROM cohort
    GROUP BY "gender"
),

min_counts AS (           -- # users at the minimum age
    SELECT
        c."gender",
        COUNT(*) AS num_min_age_users
    FROM cohort c
    JOIN age_extremes a
      ON c."gender" = a."gender"
     AND c."age"    = a.min_age
    GROUP BY c."gender"
),

max_counts AS (           -- # users at the maximum age
    SELECT
        c."gender",
        COUNT(*) AS num_max_age_users
    FROM cohort c
    JOIN age_extremes a
      ON c."gender" = a."gender"
     AND c."age"    = a.max_age
    GROUP BY c."gender"
)

SELECT
    e."gender",
    e.min_age,
    m.num_min_age_users,
    e.max_age,
    x.num_max_age_users
FROM age_extremes e
JOIN min_counts  m ON e."gender" = m."gender"
JOIN max_counts  x ON e."gender" = x."gender"
ORDER BY e."gender";