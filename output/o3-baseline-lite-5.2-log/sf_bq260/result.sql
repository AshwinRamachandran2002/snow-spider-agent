WITH "FILTERED_USERS" AS (
    SELECT 
        "id",
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_TIMESTAMP_NTZ("created_at"/1000000) >= '2019-01-01'
      AND TO_TIMESTAMP_NTZ("created_at"/1000000) <  '2022-05-01'   -- up to 30‑Apr‑2022 inclusive
      AND "gender" IS NOT NULL
),
"AGE_LIMITS" AS (
    SELECT
        "gender",
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM "FILTERED_USERS"
    GROUP BY "gender"
),
"YOUNGEST_COUNTS" AS (
    SELECT 
        f."gender",
        f."age"   AS "youngest_age",
        COUNT(*)  AS "youngest_user_count"
    FROM "FILTERED_USERS" f
    JOIN "AGE_LIMITS"  l
      ON f."gender" = l."gender"
     AND f."age"     = l."youngest_age"
    GROUP BY f."gender", f."age"
),
"OLDEST_COUNTS" AS (
    SELECT 
        f."gender",
        f."age"   AS "oldest_age",
        COUNT(*)  AS "oldest_user_count"
    FROM "FILTERED_USERS" f
    JOIN "AGE_LIMITS"  l
      ON f."gender" = l."gender"
     AND f."age"     = l."oldest_age"
    GROUP BY f."gender", f."age"
)
SELECT 
    y."gender",
    y."youngest_age",
    y."youngest_user_count",
    o."oldest_age",
    o."oldest_user_count"
FROM "YOUNGEST_COUNTS" y
JOIN "OLDEST_COUNTS"  o
  ON y."gender" = o."gender"
ORDER BY y."gender";