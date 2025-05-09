/* Youngest vs Oldest users by gender
   – sign-ups between 01-Jan-2019 and 30-Apr-2022 (inclusive) */
WITH filtered_users AS (
    SELECT *
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000    /* 2019-01-01 00:00:00 */
                         AND 1651363200000000      /* 2022-05-01 00:00:00 → includes all of 30-Apr-2022 */
),
age_bounds AS (
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM filtered_users
    GROUP BY "gender"
),
labeled AS (
    SELECT
        f."gender",
        CASE
            WHEN f."age" = b."min_age" THEN 'youngest'
            WHEN f."age" = b."max_age" THEN 'oldest'
        END                         AS "age_group_flag",
        b."min_age",
        b."max_age"
    FROM filtered_users f
    JOIN age_bounds b
      ON f."gender" = b."gender"
     AND (f."age" = b."min_age" OR f."age" = b."max_age")
)
SELECT
    "gender",
    "age_group_flag",
    CASE
        WHEN "age_group_flag" = 'youngest' THEN "min_age"
        ELSE "max_age"
    END                               AS "age_value",
    COUNT(*)                          AS "user_count"
FROM labeled
GROUP BY
    "gender",
    "age_group_flag",
    "age_value"
ORDER BY
    "gender",
    "age_group_flag";