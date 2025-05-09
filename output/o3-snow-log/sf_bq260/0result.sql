WITH filtered_users AS (
    SELECT 
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000  -- 01-Jan-2019 to 30-Apr-2022
), 
age_bounds AS (
    SELECT
        "gender",
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM filtered_users
    GROUP BY "gender"
), 
youngest_counts AS (
    SELECT
        fu."gender",
        COUNT(*) AS youngest_users_count
    FROM filtered_users fu
    JOIN age_bounds ab
          ON fu."gender" = ab."gender"
         AND fu."age"    = ab.youngest_age
    GROUP BY fu."gender"
), 
oldest_counts AS (
    SELECT
        fu."gender",
        COUNT(*) AS oldest_users_count
    FROM filtered_users fu
    JOIN age_bounds ab
          ON fu."gender" = ab."gender"
         AND fu."age"    = ab.oldest_age
    GROUP BY fu."gender"
)
SELECT
    ab."gender",
    ab.youngest_age,
    yc.youngest_users_count,
    ab.oldest_age,
    oc.oldest_users_count
FROM age_bounds      ab
LEFT JOIN youngest_counts yc ON yc."gender" = ab."gender"
LEFT JOIN oldest_counts  oc ON oc."gender" = ab."gender"
ORDER BY ab."gender";