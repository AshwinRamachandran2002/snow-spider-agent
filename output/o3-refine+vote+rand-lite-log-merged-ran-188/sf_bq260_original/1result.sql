WITH filtered_users AS (
    SELECT
        "id",
        "gender",
        "age",
        TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) AS "signup_date"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE TO_DATE(TO_TIMESTAMP("created_at" / 1000000))
          BETWEEN '2019-01-01' AND '2022-04-30'
          AND "gender" IS NOT NULL
          AND "age" IS NOT NULL
),
age_extremes AS (
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM filtered_users
    GROUP BY "gender"
),
young_old AS (
    SELECT
        f."gender",
        CASE
            WHEN f."age" = a."min_age" THEN 'youngest'
            WHEN f."age" = a."max_age" THEN 'oldest'
        END AS "age_type"
    FROM filtered_users f
    JOIN age_extremes a
      ON f."gender" = a."gender"
     AND f."age" IN (a."min_age", a."max_age")
)
SELECT
    "gender",
    "age_type",
    COUNT(*) AS "user_count"
FROM young_old
GROUP BY
    "gender",
    "age_type"
ORDER BY
    "gender",
    "age_type";