WITH filtered_users AS (
    SELECT 
        "gender",
        "age"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000   -- 2019‑01‑01 to 2022‑04‑30
),
age_limits AS (
    SELECT
        "gender",
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM filtered_users
    GROUP BY "gender"
)

SELECT
    fu."gender",
    'youngest' AS age_type,
    COUNT(*)   AS user_count
FROM filtered_users fu
JOIN age_limits al
      ON fu."gender" = al."gender"
     AND fu."age"    = al.youngest_age
GROUP BY fu."gender"

UNION ALL

SELECT
    fu."gender",
    'oldest'  AS age_type,
    COUNT(*)  AS user_count
FROM filtered_users fu
JOIN age_limits al
      ON fu."gender" = al."gender"
     AND fu."age"    = al.oldest_age
GROUP BY fu."gender"

ORDER BY 1, 2;