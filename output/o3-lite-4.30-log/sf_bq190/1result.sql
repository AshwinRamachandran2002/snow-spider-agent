WITH filtered AS (
    SELECT "gender",
           "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000   -- 2019‑01‑01 00:00:00
                          AND 1651363199000000   -- 2022‑04‑30 23:59:59
),
bounds AS (
    SELECT  "gender",
            MIN("age") AS min_age,
            MAX("age") AS max_age
    FROM filtered
    GROUP BY "gender"
),
youngest AS (
    SELECT  f."gender",
            COUNT(*) AS youngest_user_count
    FROM filtered f
    JOIN bounds b
      ON f."gender" = b."gender"
     AND f."age"    = b.min_age
    GROUP BY f."gender"
),
oldest AS (
    SELECT  f."gender",
            COUNT(*) AS oldest_user_count
    FROM filtered f
    JOIN bounds b
      ON f."gender" = b."gender"
     AND f."age"    = b.max_age
    GROUP BY f."gender"
)
SELECT  b."gender"                       AS gender,
        b.min_age                        AS min_age,
        y.youngest_user_count            AS youngest_user_count,
        b.max_age                        AS max_age,
        o.oldest_user_count              AS oldest_user_count
FROM bounds   b
LEFT JOIN youngest y ON b."gender" = y."gender"
LEFT JOIN oldest   o ON b."gender" = o."gender"
ORDER BY b."gender";