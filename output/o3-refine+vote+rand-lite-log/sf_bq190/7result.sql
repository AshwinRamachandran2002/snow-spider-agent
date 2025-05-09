WITH "filtered_users" AS (          -- users who signed‑up between 2019‑01‑01 and 2022‑04‑30
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE
        TO_TIMESTAMP("created_at" / 1000000) >= '2019-01-01'      -- 1 Jan 2019
        AND TO_TIMESTAMP("created_at" / 1000000) <  '2022-05-01'  -- up to 30 Apr 2022
        AND "gender" IS NOT NULL
),
"age_extremes" AS (                -- minimum and maximum ages per gender
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM "filtered_users"
    GROUP BY "gender"
),
"extreme_counts" AS (              -- number of users having those extreme ages
    SELECT
        f."gender",
        COUNT_IF(f."age" = e."min_age") AS "min_age_user_count",
        COUNT_IF(f."age" = e."max_age") AS "max_age_user_count"
    FROM "filtered_users" f
    JOIN "age_extremes"    e  ON f."gender" = e."gender"
    GROUP BY f."gender"
)
SELECT
    e."gender",
    e."min_age",
    c."min_age_user_count",
    e."max_age",
    c."max_age_user_count"
FROM "age_extremes"  e
JOIN "extreme_counts" c ON e."gender" = c."gender"
ORDER BY e."gender";