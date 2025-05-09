WITH extremes AS (
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000   -- 2019-01-01
                          AND 1651276800000000   -- 2022-04-30
    GROUP BY "gender"
)
SELECT
    u."gender",
    COUNT_IF(u."age" = e."min_age") AS "youngest_user_count",
    COUNT_IF(u."age" = e."max_age") AS "oldest_user_count"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
JOIN extremes e
      ON u."gender" = e."gender"
WHERE u."created_at" BETWEEN 1546300800000000
                        AND 1651276800000000
GROUP BY u."gender"
ORDER BY u."gender";