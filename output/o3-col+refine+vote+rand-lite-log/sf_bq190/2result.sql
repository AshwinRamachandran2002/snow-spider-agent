-- Youngest vs Oldest users (sign-ups between 2019-01-01 and 2022-04-30)
WITH age_extremes AS (
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
      AND "gender" IN ('M','F')                     -- keep only the two main genders
    GROUP BY "gender"
)
SELECT
    e."gender",
    'MIN'        AS "age_type",
    e."min_age"  AS "age_value",
    COUNT(*)     AS "num_of_users"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
JOIN age_extremes e
  ON u."gender" = e."gender"
 AND u."age"    = e."min_age"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
GROUP BY e."gender", e."min_age"

UNION ALL

SELECT
    e."gender",
    'MAX'        AS "age_type",
    e."max_age"  AS "age_value",
    COUNT(*)     AS "num_of_users"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
JOIN age_extremes e
  ON u."gender" = e."gender"
 AND u."age"    = e."max_age"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
GROUP BY e."gender", e."max_age"
ORDER BY "gender", "age_type";