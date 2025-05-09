/* Youngest-vs-Oldest user counts per gender between 2019-01-01 and 2022-04-30 */

WITH age_bounds AS (
    SELECT
        "gender",
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000      -- 2019-01-01
                          AND 1651276800000000      -- 2022-04-30
    GROUP BY "gender"
)

SELECT
    u."gender",
    b."youngest_age",
    SUM(CASE WHEN u."age" = b."youngest_age" THEN 1 ELSE 0 END) AS "youngest_user_count",
    b."oldest_age",
    SUM(CASE WHEN u."age" = b."oldest_age"  THEN 1 ELSE 0 END) AS "oldest_user_count"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
JOIN age_bounds b
  ON u."gender" = b."gender"
WHERE u."created_at" BETWEEN 1546300800000000
                      AND 1651276800000000
GROUP BY
    u."gender",
    b."youngest_age",
    b."oldest_age"
ORDER BY
    u."gender";