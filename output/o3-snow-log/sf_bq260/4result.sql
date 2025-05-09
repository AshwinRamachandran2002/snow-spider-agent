WITH extremes AS (       -- youngest & oldest ages per gender in the period
    SELECT  "gender",
            MIN("age") AS "youngest_age",
            MAX("age") AS "oldest_age"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE   "created_at" BETWEEN 1546300800000000          /* 2019-01-01 00:00:00 */
                              AND 1651363199000000          /* 2022-04-30 23:59:59 */
    GROUP BY "gender"
)
SELECT  u."gender",
        SUM(CASE WHEN u."age" = e."youngest_age" THEN 1 ELSE 0 END) AS "youngest_user_count",
        SUM(CASE WHEN u."age" = e."oldest_age"   THEN 1 ELSE 0 END) AS "oldest_user_count"
FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
JOIN    extremes e
       ON u."gender" = e."gender"
WHERE   u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
GROUP BY u."gender"
ORDER BY u."gender";