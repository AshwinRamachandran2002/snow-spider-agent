WITH filtered_users AS (   -- users who signed-up between 1-Jan-2019 and 30-Apr-2022
    SELECT  "gender",
            "age"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE   "created_at" BETWEEN 1546300800000000   -- 2019-01-01 00:00:00
                            AND     1651363200000000 -- 2022-04-30 23:59:59
),
age_bounds AS (            -- minimum & maximum age per gender
    SELECT  "gender",
            MIN("age") AS "min_age",
            MAX("age") AS "max_age"
    FROM    filtered_users
    GROUP BY "gender"
),
youngest_oldest AS (       -- keep only users at the age extremes
    SELECT  f."gender",
            CASE 
                 WHEN f."age" = b."min_age" THEN 'youngest'
                 WHEN f."age" = b."max_age" THEN 'oldest'
            END                 AS "age_group",
            f."age"             AS "age_value"
    FROM    filtered_users f
    JOIN    age_bounds     b
      ON    f."gender" = b."gender"
     AND    (f."age" = b."min_age" OR f."age" = b."max_age")
)
SELECT  "gender",
        "age_group",       -- 'youngest' or 'oldest'
        "age_value",       -- corresponding age (min or max)
        COUNT(*) AS "num_users"
FROM    youngest_oldest
GROUP BY "gender", "age_group", "age_value"
ORDER BY "gender", "age_group";