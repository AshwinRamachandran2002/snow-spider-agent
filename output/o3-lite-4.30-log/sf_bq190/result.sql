WITH age_bounds AS (
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
      AND "gender" IN ('M','F')
    GROUP BY "gender"
)
SELECT
    ab."gender",
    ab."min_age",
    COUNT_IF(u."age" = ab."min_age") AS "youngest_user_count",
    ab."max_age",
    COUNT_IF(u."age" = ab."max_age") AS "oldest_user_count"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
JOIN age_bounds ab
  ON u."gender" = ab."gender"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
GROUP BY
    ab."gender",
    ab."min_age",
    ab."max_age"
ORDER BY
    ab."gender";