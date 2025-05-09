WITH filtered AS (
    SELECT "gender",
           "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
),
age_edges AS (
    SELECT "gender",
           MIN("age") AS min_age,
           MAX("age") AS max_age
    FROM filtered
    GROUP BY "gender"
),
youngest AS (
    SELECT f."gender",
           COUNT(*) AS youngest_user_count
    FROM filtered f
    JOIN age_edges e
      ON f."gender" = e."gender"
     AND f."age"    = e.min_age
    GROUP BY f."gender"
),
oldest AS (
    SELECT f."gender",
           COUNT(*) AS oldest_user_count
    FROM filtered f
    JOIN age_edges e
      ON f."gender" = e."gender"
     AND f."age"    = e.max_age
    GROUP BY f."gender"
)
SELECT e."gender"                                              AS gender,
       e.min_age                                               AS min_age,
       y.youngest_user_count                                   AS youngest_user_count,
       e.max_age                                               AS max_age,
       o.oldest_user_count                                     AS oldest_user_count
FROM age_edges e
JOIN youngest y ON e."gender" = y."gender"
JOIN oldest  o ON e."gender" = o."gender"
ORDER BY e."gender";