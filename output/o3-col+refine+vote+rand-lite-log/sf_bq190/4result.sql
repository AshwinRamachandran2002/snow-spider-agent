WITH filtered_users AS (
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651276800000000
          AND "gender" IN ('M','F')          -- keep only the two genders of interest
), age_bounds AS (
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM filtered_users
    GROUP BY "gender"
), age_counts AS (
    SELECT
        f."gender",
        b."min_age",
        b."max_age",
        SUM(CASE WHEN f."age" = b."min_age" THEN 1 ELSE 0 END) AS "min_age_user_count",
        SUM(CASE WHEN f."age" = b."max_age" THEN 1 ELSE 0 END) AS "max_age_user_count"
    FROM filtered_users f
    JOIN age_bounds b
      ON f."gender" = b."gender"
    GROUP BY
        f."gender",
        b."min_age",
        b."max_age"
)
SELECT
    "gender",
    "min_age",
    "min_age_user_count",
    "max_age",
    "max_age_user_count"
FROM age_counts
ORDER BY "gender";