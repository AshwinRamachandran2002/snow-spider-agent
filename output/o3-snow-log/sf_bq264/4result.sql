/*  Difference between the number of the oldest-aged users and the youngest-aged users
    who registered from 2019-01-01 through 2022-04-30                  */

WITH "USERS_IN_RANGE" AS (
    SELECT
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) 
          BETWEEN '2019-01-01' AND '2022-04-30'
),
"EXTREMES" AS (
    SELECT
        MAX("age") AS "OLDEST_AGE",
        MIN("age") AS "YOUNGEST_AGE"
    FROM "USERS_IN_RANGE"
),
"COUNTS" AS (
    SELECT
        SUM(CASE WHEN u."age" = e."OLDEST_AGE"   THEN 1 ELSE 0 END) AS "OLDEST_COUNT",
        SUM(CASE WHEN u."age" = e."YOUNGEST_AGE" THEN 1 ELSE 0 END) AS "YOUNGEST_COUNT"
    FROM "USERS_IN_RANGE" u
    CROSS JOIN "EXTREMES" e
)
SELECT
    "OLDEST_COUNT" - "YOUNGEST_COUNT" AS "DIFFERENCE_OLDEST_VS_YOUNGEST"
FROM "COUNTS";