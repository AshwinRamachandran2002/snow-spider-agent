/* Youngest & Oldest Users (per Gender) who signed up between 2019‑01‑01 and 2022‑04‑30 */

WITH filtered_users AS (          -- keep only users in the required sign‑up window
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE
        TO_TIMESTAMP_NTZ("created_at" / 1000000) >= '2019-01-01'  -- inclusive
        AND TO_TIMESTAMP_NTZ("created_at" / 1000000) <= '2022-04-30'  -- inclusive
        AND "gender" IN ('M', 'F')        -- only male & female
),

age_extremes AS (                 -- find youngest (min) & oldest (max) age per gender
    SELECT
        "gender",
        MIN("age") AS min_age,
        MAX("age") AS max_age
    FROM filtered_users
    GROUP BY "gender"
)

SELECT
    f."gender",                                           -- M or F
    CASE
        WHEN f."age" = e.min_age THEN 'youngest'
        ELSE 'oldest'
    END                     AS "age_group",               -- youngest / oldest
    f."age"                 AS "age",                     -- the min or max age itself
    COUNT(*)                AS "user_count"               -- # users at that exact age
FROM filtered_users   f
JOIN age_extremes     e
      ON f."gender" = e."gender"
WHERE f."age" IN (e.min_age, e.max_age)                   -- keep only min / max ages
GROUP BY
    f."gender",
    "age_group",
    f."age"
ORDER BY
    f."gender",
    "age_group";