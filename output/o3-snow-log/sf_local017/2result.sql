WITH TOP_CAUSES AS (      -- count each cause per year and rank them
    SELECT 
        ci."db_year"                                     AS "YEAR",
        c."pcf_violation_category"                       AS "CAUSE",
        COUNT(*)                                         AS "CNT",
        DENSE_RANK() OVER (PARTITION BY ci."db_year"
                            ORDER BY COUNT(*) DESC)      AS "RNK"
    FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"  c
    JOIN "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."CASE_IDS"     ci
          ON c."case_id" = ci."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
      AND TRIM(c."pcf_violation_category") <> ''
    GROUP BY ci."db_year", c."pcf_violation_category"
), YEAR_COMBOS AS (       -- keep only the top-2 causes for each year and concatenate them
    SELECT
        "YEAR",
        LISTAGG("CAUSE", ',') 
          WITHIN GROUP (ORDER BY "RNK")                  AS "TOP2_COMBO"
    FROM TOP_CAUSES
    WHERE "RNK" <= 2
    GROUP BY "YEAR"
    HAVING COUNT(*) = 2                                  -- ensure the year actually has two causes
), COMBO_FREQ AS (       -- how many years share the same pair
    SELECT 
        "TOP2_COMBO",
        COUNT(*) AS "YEARS_WITH_COMBO"
    FROM YEAR_COMBOS
    GROUP BY "TOP2_COMBO"
)
SELECT 
    yc."YEAR"
FROM YEAR_COMBOS yc
JOIN COMBO_FREQ  cf
  ON yc."TOP2_COMBO" = cf."TOP2_COMBO"
WHERE cf."YEARS_WITH_COMBO" = 1                         -- pair appears in only one year
ORDER BY yc."YEAR";