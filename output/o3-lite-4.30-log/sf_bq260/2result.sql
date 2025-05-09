WITH per_gender_min AS (
    SELECT
        "gender",
        MIN("age") AS "age_boundary",
        'youngest' AS "age_type"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY "gender"
),
per_gender_max AS (
    SELECT
        "gender",
        MAX("age") AS "age_boundary",
        'oldest'  AS "age_type"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY "gender"
),
age_bounds AS (
    SELECT * FROM per_gender_min
    UNION ALL
    SELECT * FROM per_gender_max
)
SELECT
    ab."gender",
    ab."age_type",
    COUNT(*) AS "user_count"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
JOIN age_bounds ab
      ON u."gender" = ab."gender"
     AND u."age"    = ab."age_boundary"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
GROUP BY ab."gender", ab."age_type"
ORDER BY ab."gender", ab."age_type";