WITH date_filtered AS (  -- users created between 2019‑01‑01 and 2022‑04‑30
    SELECT 
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000       -- 2019‑01‑01 00:00:00
                          AND 1651363199000000        -- 2022‑04‑30 23:59:59
),
age_extremes AS (        -- youngest & oldest age per gender in that period
    SELECT
        "gender",
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM date_filtered
    GROUP BY "gender"
),
youngest_cnt AS (        -- count of users at the youngest age per gender
    SELECT
        df."gender",
        COUNT(*) AS youngest_age_user_count
    FROM date_filtered df
    JOIN age_extremes ae
      ON df."gender" = ae."gender"
     AND df."age"    = ae.youngest_age
    GROUP BY df."gender"
),
oldest_cnt AS (          -- count of users at the oldest age per gender
    SELECT
        df."gender",
        COUNT(*) AS oldest_age_user_count
    FROM date_filtered df
    JOIN age_extremes ae
      ON df."gender" = ae."gender"
     AND df."age"    = ae.oldest_age
    GROUP BY df."gender"
)
SELECT
    g."gender",
    COALESCE(y.youngest_age_user_count, 0) AS youngest_age_user_count,
    COALESCE(o.oldest_age_user_count , 0) AS oldest_age_user_count
FROM (SELECT DISTINCT "gender" FROM date_filtered) g
LEFT JOIN youngest_cnt y ON g."gender" = y."gender"
LEFT JOIN oldest_cnt  o ON g."gender" = o."gender"
ORDER BY g."gender";