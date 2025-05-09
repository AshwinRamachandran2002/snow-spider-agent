WITH filtered_users AS (
    SELECT
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "age" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) BETWEEN '2019-01-01' AND '2022-04-30'
),
age_counts AS (
    SELECT
        "age",
        COUNT(*) AS user_count
    FROM filtered_users
    GROUP BY "age"
),
oldest AS (
    SELECT
        "age",
        user_count
    FROM age_counts
    ORDER BY "age" DESC NULLS LAST
    LIMIT 1
),
youngest AS (
    SELECT
        "age",
        user_count
    FROM age_counts
    ORDER BY "age" ASC NULLS LAST
    LIMIT 1
)
SELECT
    oldest."age"        AS "OLDEST_AGE",
    oldest.user_count   AS "OLDEST_USERS",
    youngest."age"      AS "YOUNGEST_AGE",
    youngest.user_count AS "YOUNGEST_USERS",
    ABS(oldest.user_count - youngest.user_count) AS "DIFFERENCE_IN_NUMBER"
FROM oldest
CROSS JOIN youngest;