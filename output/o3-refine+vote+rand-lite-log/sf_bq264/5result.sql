WITH "FILTERED_USERS" AS (   -- users registered between 2019‑01‑01 and 2022‑04‑30
    SELECT 
        "id",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) 
          BETWEEN '2019-01-01' AND '2022-04-30'
), 
"AGE_LIMITS" AS (            -- find the oldest and youngest ages in that period
    SELECT 
        MAX("age") AS "MAX_AGE",
        MIN("age") AS "MIN_AGE"
    FROM "FILTERED_USERS"
), 
"AGE_COUNTS" AS (            -- count how many users have those ages
    SELECT
        SUM(CASE WHEN fu."age" = al."MAX_AGE" THEN 1 ELSE 0 END) AS "OLDEST_COUNT",
        SUM(CASE WHEN fu."age" = al."MIN_AGE" THEN 1 ELSE 0 END) AS "YOUNGEST_COUNT"
    FROM "FILTERED_USERS" fu, "AGE_LIMITS" al
)
SELECT 
    ABS("OLDEST_COUNT" - "YOUNGEST_COUNT") 
        AS "DIFFERENCE_BETWEEN_OLDEST_AND_YOUNGEST_USER_COUNTS"
FROM "AGE_COUNTS";