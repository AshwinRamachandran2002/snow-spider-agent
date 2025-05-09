WITH sex_avg AS (
    SELECT
        "FEATURE_NAME",
        AVG(CASE WHEN "SEX" = 'female' THEN "X_VALUE" END) AS "avg_female",
        AVG(CASE WHEN "SEX" = 'male'   THEN "X_VALUE" END) AS "avg_male"
    FROM HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
    WHERE "CELL_TYPE" ILIKE '%epithelial%'
      AND "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" ILIKE '%74-year-old%'
    GROUP BY "FEATURE_NAME"
    HAVING COUNT(DISTINCT "SEX") = 2           -- keep genes with both sexes present
)
SELECT
    "FEATURE_NAME",
    "avg_female",
    "avg_male",
    "avg_female" - "avg_male" AS "female_minus_male"
FROM sex_avg
ORDER BY "female_minus_male" DESC NULLS LAST
LIMIT 20;