WITH "FILTERED_USERS" AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_TIMESTAMP("created_at" / 1000000) 
          BETWEEN '2019-01-01'::TIMESTAMP 
              AND '2022-04-30 23:59:59'::TIMESTAMP
),
"AGE_EXTREMES" AS (
    SELECT 
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM "FILTERED_USERS"
),
"AGE_COUNTS" AS (
    SELECT
        SUM(CASE WHEN "age" = (SELECT "youngest_age" FROM "AGE_EXTREMES") THEN 1 ELSE 0 END) AS "youngest_count",
        SUM(CASE WHEN "age" = (SELECT "oldest_age"  FROM "AGE_EXTREMES") THEN 1 ELSE 0 END)  AS "oldest_count"
    FROM "FILTERED_USERS"
)
SELECT 
    ABS("oldest_count" - "youngest_count") AS "difference_in_user_counts"
FROM "AGE_COUNTS";