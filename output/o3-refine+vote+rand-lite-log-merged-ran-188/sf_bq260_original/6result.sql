WITH "FILTERED_USERS" AS (   -- users created between 2019‑01‑01 and 2022‑04‑30
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_TIMESTAMP("created_at" / 1000000) >= '2019-01-01'
      AND TO_TIMESTAMP("created_at" / 1000000) <  '2022-05-01'   -- up to 2022‑04‑30 23:59:59
      AND "gender" IS NOT NULL
      AND "age"    IS NOT NULL
),
"AGE_BOUNDS" AS (            -- youngest & oldest age for every gender
    SELECT
        "gender",
        MIN("age") AS "YOUNGEST_AGE",
        MAX("age") AS "OLDEST_AGE"
    FROM "FILTERED_USERS"
    GROUP BY "gender"
),
"YOUNGEST_COUNTS" AS (       -- count of users at the youngest age
    SELECT
        f."gender",
        COUNT(*) AS "YOUNGEST_USERS_COUNT"
    FROM "FILTERED_USERS" f
    JOIN "AGE_BOUNDS"    b
      ON f."gender" = b."gender"
     AND f."age"    = b."YOUNGEST_AGE"
    GROUP BY f."gender"
),
"OLDEST_COUNTS" AS (         -- count of users at the oldest age
    SELECT
        f."gender",
        COUNT(*) AS "OLDEST_USERS_COUNT"
    FROM "FILTERED_USERS" f
    JOIN "AGE_BOUNDS"    b
      ON f."gender" = b."gender"
     AND f."age"    = b."OLDEST_AGE"
    GROUP BY f."gender"
)
SELECT
    b."gender",
    b."YOUNGEST_AGE",
    y."YOUNGEST_USERS_COUNT",
    b."OLDEST_AGE",
    o."OLDEST_USERS_COUNT"
FROM "AGE_BOUNDS"  b
LEFT JOIN "YOUNGEST_COUNTS" y ON b."gender" = y."gender"
LEFT JOIN "OLDEST_COUNTS"  o ON b."gender" = o."gender"
ORDER BY b."gender";