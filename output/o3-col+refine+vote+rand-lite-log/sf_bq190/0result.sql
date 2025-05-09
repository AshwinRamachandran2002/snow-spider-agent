WITH cohort AS (   -- users who signed-up 2019-01-01 thru 2022-04-30
    SELECT "id",
           "gender",
           "age"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE "created_at" BETWEEN 1546300800000000            -- 2019-01-01
                           AND 1651363200000000            -- 2022-04-30
      AND "gender" IN ('M','F')
),
age_bounds AS (     -- youngest & oldest age per gender
    SELECT "gender",
           MIN("age") AS "min_age",
           MAX("age") AS "max_age"
    FROM cohort
    GROUP BY "gender"
),
min_age_users AS (  -- how many users are at the minimum age
    SELECT c."gender",
           COUNT(*) AS "num_users_min_age"
    FROM cohort c
    JOIN age_bounds a
      ON c."gender" = a."gender"
     AND c."age"    = a."min_age"
    GROUP BY c."gender"
),
max_age_users AS (  -- how many users are at the maximum age
    SELECT c."gender",
           COUNT(*) AS "num_users_max_age"
    FROM cohort c
    JOIN age_bounds a
      ON c."gender" = a."gender"
     AND c."age"    = a."max_age"
    GROUP BY c."gender"
)
SELECT a."gender",
       a."min_age",
       m."num_users_min_age",
       a."max_age",
       x."num_users_max_age"
FROM   age_bounds       a
LEFT  JOIN min_age_users m ON a."gender" = m."gender"
LEFT  JOIN max_age_users x ON a."gender" = x."gender"
ORDER BY a."gender";