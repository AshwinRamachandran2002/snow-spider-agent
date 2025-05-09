/* ------------------------------------------------------------
   Youngest & Oldest user counts (by gender) for sign-ups between
   01-Jan-2019 00:00 UTC  and  30-Apr-2022 23:59 UTC
   ------------------------------------------------------------ */
WITH filtered AS (      -- keep only users in the required period
    SELECT "id",
           "gender",
           "age"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE  "created_at" BETWEEN 1546300800000000  -- 01-Jan-2019
                           AND   1651363200000000  -- 30-Apr-2022
      AND  "gender" IN ('F','M')                  -- focus on male / female
),
age_bounds AS (         -- find youngest & oldest ages in that period, per gender
    SELECT "gender",
           MIN("age") AS min_age,
           MAX("age") AS max_age
    FROM   filtered
    GROUP  BY "gender"
),
flagged AS (            -- mark every user who is at the gender-specific extreme
    SELECT  f."gender",
            CASE
               WHEN f."age" = ab.min_age THEN 'youngest'
               ELSE 'oldest'
            END        AS age_group,
            f."age"    AS age_value
    FROM    filtered f
    JOIN    age_bounds ab
           ON f."gender" = ab."gender"
          AND (f."age" = ab.min_age OR f."age" = ab.max_age)
)
SELECT  "gender",
        age_group,      -- 'youngest' or 'oldest'
        age_value,      -- the actual minimum / maximum age
        COUNT(*) AS user_cnt
FROM    flagged
GROUP BY "gender", age_group, age_value
ORDER BY "gender", age_group;