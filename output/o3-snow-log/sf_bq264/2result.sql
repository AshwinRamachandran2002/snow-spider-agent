WITH "FILTERED_USERS" AS (   -- users registered between 2019-01-01 and 2022-04-30
    SELECT
        "id",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "age" IS NOT NULL
      AND TO_TIMESTAMP("created_at" / 1000000) >= '2019-01-01'
      AND TO_TIMESTAMP("created_at" / 1000000) <= '2022-04-30 23:59:59'
),
"AGE_BOUNDS" AS (            -- oldest and youngest ages in that period
    SELECT
        MAX("age") AS "OLDEST_AGE",
        MIN("age") AS "YOUNGEST_AGE"
    FROM "FILTERED_USERS"
),
"COUNTS" AS (                -- counts of users with those ages
    SELECT
        (SELECT COUNT(*) 
           FROM "FILTERED_USERS" 
          WHERE "age" = (SELECT "OLDEST_AGE" FROM "AGE_BOUNDS"))     AS "OLDEST_COUNT",
        (SELECT COUNT(*) 
           FROM "FILTERED_USERS" 
          WHERE "age" = (SELECT "YOUNGEST_AGE" FROM "AGE_BOUNDS"))   AS "YOUNGEST_COUNT"
)
SELECT
    ABS("OLDEST_COUNT" - "YOUNGEST_COUNT") AS "AGE_COUNT_DIFFERENCE"
FROM "COUNTS";