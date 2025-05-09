WITH "COUNTS" AS (   -- accidents per year & cause
    SELECT
        ci."db_year"              AS "YEAR",
        cl."pcf_violation_category" AS "CAUSE",
        COUNT(*)                  AS "CNT"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS" cl
    JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."CASE_IDS"  ci
      ON cl."case_id" = ci."case_id"
    WHERE cl."pcf_violation_category" IS NOT NULL
    GROUP BY ci."db_year", cl."pcf_violation_category"
),
"TOP2" AS (          -- keep only the two most frequent causes each year
    SELECT
        "YEAR",
        "CAUSE",
        ROW_NUMBER() OVER (PARTITION BY "YEAR"
                           ORDER BY "CNT" DESC NULLS LAST) AS "RN"
    FROM "COUNTS"
),
"PAIR_BY_YEAR" AS (  -- alphabetically-sorted pair string for each year
    SELECT
        "YEAR",
        LISTAGG("CAUSE", ',') WITHIN GROUP (ORDER BY "CAUSE") AS "TOP_TWO_CAUSES"
    FROM "TOP2"
    WHERE "RN" <= 2
    GROUP BY "YEAR"
),
"PAIR_FREQ" AS (     -- how many different years share the same pair
    SELECT
        "TOP_TWO_CAUSES",
        COUNT(*) AS "YEARS_WITH_PAIR"
    FROM "PAIR_BY_YEAR"
    GROUP BY "TOP_TWO_CAUSES"
)
SELECT
    p."YEAR"
FROM "PAIR_BY_YEAR" p
JOIN "PAIR_FREQ" f
  ON p."TOP_TWO_CAUSES" = f."TOP_TWO_CAUSES"
WHERE f."YEARS_WITH_PAIR" = 1          -- pair appears in exactly one year
ORDER BY p."YEAR";