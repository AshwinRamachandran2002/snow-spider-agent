WITH gene_avg AS (
    SELECT
        "FEATURE_NAME",
        AVG(CASE WHEN LOWER("SEX") = 'female' THEN "X_VALUE" END) AS avg_female_raw,
        AVG(CASE WHEN LOWER("SEX") = 'male'   THEN "X_VALUE" END) AS avg_male_raw
    FROM HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
    WHERE "CELL_TYPE_COARSE" = 'Epithelial'
      AND "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" = '74-year-old human stage'
    GROUP BY "FEATURE_NAME"
)
SELECT
    "FEATURE_NAME",
    ROUND(avg_female_raw, 4) AS "avg_female",
    ROUND(avg_male_raw,   4) AS "avg_male",
    ROUND(avg_female_raw - avg_male_raw, 4) AS "diff_female_minus_male"
FROM gene_avg
WHERE avg_female_raw IS NOT NULL
  AND avg_male_raw   IS NOT NULL
ORDER BY "diff_female_minus_male" DESC NULLS LAST,
         "FEATURE_NAME"
LIMIT 20;