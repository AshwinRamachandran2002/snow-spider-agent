WITH "COLLISIONS_PER_YEAR" AS (
    SELECT
        ci."db_year" AS "year",
        c."pcf_violation_category" AS "category",
        COUNT(*)                           AS "cnt"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS"     c
    JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."CASE_IDS"  ci
          ON c."case_id" = ci."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
      AND c."pcf_violation_category" <> ''
    GROUP BY
        ci."db_year",
        c."pcf_violation_category"
),
"RANKED" AS (
    SELECT
        "year",
        "category",
        "cnt",
        ROW_NUMBER() OVER (
            PARTITION BY "year"
            ORDER BY "cnt" DESC NULLS LAST, "category"
        ) AS "rn"
    FROM "COLLISIONS_PER_YEAR"
),
"TOP2" AS (
    SELECT
        "year",
        LISTAGG("category", ' | ') WITHIN GROUP (ORDER BY "rn") AS "top2_categories"
    FROM "RANKED"
    WHERE "rn" <= 2
    GROUP BY "year"
),
"PAIR_FREQ" AS (
    SELECT
        "top2_categories",
        COUNT(*) AS "years_with_pair"
    FROM "TOP2"
    GROUP BY "top2_categories"
),
"UNIQUE_YEARS" AS (
    SELECT
        t."year"
    FROM "TOP2" t
    JOIN "PAIR_FREQ" p
      ON t."top2_categories" = p."top2_categories"
    WHERE p."years_with_pair" = 1
)
SELECT DISTINCT
       "year"
FROM "UNIQUE_YEARS"
ORDER BY "year";