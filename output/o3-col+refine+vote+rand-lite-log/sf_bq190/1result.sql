/* Youngest & oldest user counts per gender for sign-ups between
   01-Jan-2019 (1546300800000000 µs) and 30-Apr-2022 (1651363200000000 µs) */

WITH restricted_users AS (          -- users within the requested window
    SELECT
        "id",
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363200000000
      AND "gender" IN ('M','F')
),
age_extremes AS (                   -- min & max age per gender
    SELECT
        "gender",
        MIN("age") AS min_age_in_range,
        MAX("age") AS max_age_in_range
    FROM restricted_users
    GROUP BY "gender"
),
flagged AS (                        -- keep only users at the extremes
    SELECT
        ru."gender",
        ru."age",
        CASE
            WHEN ru."age" = ae.min_age_in_range THEN 'youngest'
            WHEN ru."age" = ae.max_age_in_range THEN 'oldest'
        END AS age_flag
    FROM restricted_users ru
    JOIN age_extremes      ae
      ON ru."gender" = ae."gender"
    WHERE ru."age" IN (ae.min_age_in_range, ae.max_age_in_range)
)
SELECT
    ae."gender",
    ae.min_age_in_range      AS "youngest_age",
    SUM(CASE WHEN f.age_flag = 'youngest' THEN 1 ELSE 0 END) AS "youngest_user_count",
    ae.max_age_in_range      AS "oldest_age",
    SUM(CASE WHEN f.age_flag = 'oldest'   THEN 1 ELSE 0 END) AS "oldest_user_count"
FROM age_extremes ae
LEFT JOIN flagged f
       ON ae."gender" = f."gender"
GROUP BY
    ae."gender",
    ae.min_age_in_range,
    ae.max_age_in_range
ORDER BY
    ae."gender";