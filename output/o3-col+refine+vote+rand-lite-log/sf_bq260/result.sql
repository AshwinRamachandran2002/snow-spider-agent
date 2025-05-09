/* Youngest vs oldest user counts per gender between 01-Jan-2019 and 30-Apr-2022 */
WITH age_bounds AS (
    SELECT
        "gender",
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE "created_at" BETWEEN 1546300800000000  -- 2019-01-01 00:00:00
                          AND 1651363199000000  -- 2022-04-30 23:59:59
    GROUP BY "gender"
)

SELECT
    ab."gender",
    ab."youngest_age",
    SUM(CASE WHEN u."age" = ab."youngest_age" THEN 1 ELSE 0 END) AS "users_at_youngest_age",
    ab."oldest_age",
    SUM(CASE WHEN u."age" = ab."oldest_age"  THEN 1 ELSE 0 END) AS "users_at_oldest_age"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" u
JOIN age_bounds ab
  ON u."gender" = ab."gender"
WHERE u."created_at" BETWEEN 1546300800000000
                       AND 1651363199000000
GROUP BY
    ab."gender",
    ab."youngest_age",
    ab."oldest_age"
ORDER BY
    ab."gender";