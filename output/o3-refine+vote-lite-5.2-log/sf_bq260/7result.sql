WITH "FILTERED_USERS" AS (       -- users created between 2019‑01‑01 and 2022‑04‑30
    SELECT
        "id",
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "gender" IS NOT NULL
      AND TO_DATE( TO_TIMESTAMP_NTZ( "created_at" / 1000000 ) )
          BETWEEN '2019-01-01' AND '2022-04-30'
),
"AGE_LIMITS" AS (                -- youngest and oldest age per gender
    SELECT
        "gender",
        MIN("age") AS "YOUNGEST_AGE",
        MAX("age") AS "OLDEST_AGE"
    FROM "FILTERED_USERS"
    GROUP BY "gender"
)
SELECT
    f."gender",
    SUM( CASE WHEN f."age" = a."YOUNGEST_AGE" THEN 1 ELSE 0 END ) AS "YOUNGEST_USERS_COUNT",
    SUM( CASE WHEN f."age" = a."OLDEST_AGE"  THEN 1 ELSE 0 END ) AS "OLDEST_USERS_COUNT"
FROM "FILTERED_USERS" f
JOIN "AGE_LIMITS"  a
  ON f."gender" = a."gender"
GROUP BY f."gender"
ORDER BY f."gender";