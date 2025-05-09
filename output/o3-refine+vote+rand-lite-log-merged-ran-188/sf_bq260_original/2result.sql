WITH "filtered_users" AS (
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "gender" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) 
          BETWEEN '2019-01-01' AND '2022-04-30'
),
"age_extremes" AS (
    SELECT
        "gender",
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM "filtered_users"
    GROUP BY "gender"
),
"youngest_counts" AS (
    SELECT
        f."gender",
        COUNT(*) AS "youngest_age_user_count"
    FROM "filtered_users" f
    JOIN "age_extremes" e
      ON f."gender" = e."gender"
     AND f."age"    = e."youngest_age"
    GROUP BY f."gender"
),
"oldest_counts" AS (
    SELECT
        f."gender",
        COUNT(*) AS "oldest_age_user_count"
    FROM "filtered_users" f
    JOIN "age_extremes" e
      ON f."gender" = e."gender"
     AND f."age"    = e."oldest_age"
    GROUP BY f."gender"
)
SELECT
    e."gender",
    e."youngest_age",
    y."youngest_age_user_count",
    e."oldest_age",
    o."oldest_age_user_count"
FROM "age_extremes"   e
LEFT JOIN "youngest_counts" y USING ("gender")
LEFT JOIN "oldest_counts"   o USING ("gender")
ORDER BY e."gender";