WITH "FILTERED_USERS" AS (
    /* Users registered between 2019‑01‑01 and 2022‑04‑30 (inclusive) */
    SELECT
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_TIMESTAMP("created_at" / 1000000)::DATE BETWEEN '2019-01-01' AND '2022-04-30'
),
"EXTREMES" AS (
    /* Youngest and oldest ages in the filtered cohort */
    SELECT 
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM "FILTERED_USERS"
),
"COUNTS" AS (
    /* Count how many users have the youngest or oldest age */
    SELECT
        fu."age",
        COUNT(*) AS "user_count"
    FROM "FILTERED_USERS" fu
    JOIN "EXTREMES" e
      ON fu."age" IN (e."youngest_age", e."oldest_age")
    GROUP BY fu."age"
),
"RESULT" AS (
    SELECT
        MAX(CASE WHEN "age" = (SELECT "oldest_age"  FROM "EXTREMES")   THEN "user_count" END) AS "oldest_user_count",
        MAX(CASE WHEN "age" = (SELECT "youngest_age" FROM "EXTREMES")  THEN "user_count" END) AS "youngest_user_count"
    FROM "COUNTS"
)
SELECT
    "oldest_user_count",
    "youngest_user_count",
    ABS("oldest_user_count" - "youngest_user_count") AS "difference_in_user_count"
FROM "RESULT";