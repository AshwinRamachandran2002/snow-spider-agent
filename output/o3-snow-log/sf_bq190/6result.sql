/* Youngest & oldest users (and their counts) by gender 
   Sign-up window: 01-Jan-2019 ‑- 30-Apr-2022                   */

WITH filtered_users AS (   -- keep only sign-ups in the requested period
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000          -- 01-Jan-2019 00:00:00
                          AND 1651363199000000           -- 30-Apr-2022 23:59:59
),

age_extremes AS (          -- min & max age per gender
    SELECT
        "gender",
        MIN("age") AS min_age,
        MAX("age") AS max_age
    FROM filtered_users
    GROUP BY "gender"
),

min_age_counts AS (        -- how many users are at the gender’s minimum age?
    SELECT
        f."gender",
        COUNT(*) AS min_age_user_count
    FROM filtered_users f
    JOIN age_extremes e
      ON f."gender" = e."gender"
     AND f."age"    = e.min_age
    GROUP BY f."gender"
),

max_age_counts AS (        -- how many users are at the gender’s maximum age?
    SELECT
        f."gender",
        COUNT(*) AS max_age_user_count
    FROM filtered_users f
    JOIN age_extremes e
      ON f."gender" = e."gender"
     AND f."age"    = e.max_age
    GROUP BY f."gender"
)

SELECT
    e."gender",
    e.min_age,
    mc.min_age_user_count,
    e.max_age,
    xc.max_age_user_count
FROM age_extremes e
LEFT JOIN min_age_counts mc ON e."gender" = mc."gender"
LEFT JOIN max_age_counts xc ON e."gender" = xc."gender"
ORDER BY e."gender";