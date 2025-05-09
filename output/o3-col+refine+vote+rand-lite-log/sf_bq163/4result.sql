WITH gene_avgs AS (
    SELECT
        "FEATURE_NAME",
        AVG(CASE WHEN "SEX" = 'female' THEN "X_VALUE" END) AS female_avg,
        AVG(CASE WHEN "SEX" = 'male'   THEN "X_VALUE" END) AS male_avg
    FROM "HTAN_2"."HTAN"."SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT"
    WHERE "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" = '74-year-old human stage'
      AND "CELL_TYPE" ILIKE '%epithelial%'
      AND "SEX" IN ('female', 'male')
    GROUP BY "FEATURE_NAME"
)
SELECT
    "FEATURE_NAME",
    female_avg - male_avg AS "female_minus_male_avg"
FROM gene_avgs
WHERE female_avg IS NOT NULL
  AND male_avg IS NOT NULL
ORDER BY "female_minus_male_avg" DESC NULLS LAST
LIMIT 20;