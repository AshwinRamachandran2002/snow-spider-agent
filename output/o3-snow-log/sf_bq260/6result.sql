WITH "bounds" AS (
    SELECT  "gender",
            MIN("age") AS "youngest_age",
            MAX("age") AS "oldest_age"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE   "created_at" BETWEEN 1546300800000000   -- 2019-01-01 00:00:00
                            AND 1651363199000000   -- 2022-04-30 23:59:59
    GROUP BY "gender"
)
SELECT  u."gender",
        CASE 
            WHEN u."age" = b."youngest_age" THEN 'Youngest'
            WHEN u."age" = b."oldest_age"   THEN 'Oldest'
        END                           AS "age_group",
        u."age",
        COUNT(*)                      AS "user_count"
FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"  u
JOIN    "bounds" b
      ON u."gender" = b."gender"
     AND (u."age" = b."youngest_age" OR u."age" = b."oldest_age")
WHERE   u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
GROUP BY u."gender",
         "age_group",
         u."age"
ORDER BY u."gender",
         "age_group";