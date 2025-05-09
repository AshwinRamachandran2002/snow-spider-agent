/* Determine, for users who signed up between 01-Jan-2019 and 30-Apr-2022,
   (1) the minimum and maximum ages per gender and
   (2) how many users fall into each of those two age groups. */

WITH age_extremes AS (
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363200000000   -- 2019-01-01 to 2022-04-30 in µs
    GROUP BY "gender"
)

SELECT
    u."gender",
    ae."min_age",
    COUNT(CASE WHEN u."age" = ae."min_age" THEN 1 END) AS "users_at_min_age",
    ae."max_age",
    COUNT(CASE WHEN u."age" = ae."max_age" THEN 1 END) AS "users_at_max_age"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" u
JOIN age_extremes ae
  ON u."gender" = ae."gender"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363200000000
GROUP BY u."gender", ae."min_age", ae."max_age"
ORDER BY u."gender";