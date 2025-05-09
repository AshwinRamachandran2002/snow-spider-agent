WITH date_filtered AS (
    SELECT "id",
           "age",
           "gender"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000     -- 2019-01-01 00:00:00 UTC
                          AND 1651363199000000     -- 2022-04-30 23:59:59 UTC
), 
bounds AS (
    SELECT "gender",
           MIN("age") AS "youngest_age",
           MAX("age") AS "oldest_age"
    FROM date_filtered
    GROUP BY "gender"
), 
youngest_counts AS (
    SELECT d."gender",
           COUNT(*) AS "youngest_user_count"
    FROM date_filtered d
    JOIN bounds b
         ON d."gender" = b."gender"
        AND d."age"    = b."youngest_age"
    GROUP BY d."gender"
), 
oldest_counts AS (
    SELECT d."gender",
           COUNT(*) AS "oldest_user_count"
    FROM date_filtered d
    JOIN bounds b
         ON d."gender" = b."gender"
        AND d."age"    = b."oldest_age"
    GROUP BY d."gender"
)
SELECT b."gender",
       b."youngest_age",
       y."youngest_user_count",
       b."oldest_age",
       o."oldest_user_count"
FROM bounds b
LEFT JOIN youngest_counts y ON b."gender" = y."gender"
LEFT JOIN oldest_counts o   ON b."gender" = o."gender"
ORDER BY b."gender";