WITH filtered AS (
    SELECT
        "FEATURE_NAME",
        "SEX",
        "X_VALUE"
    FROM HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
    WHERE "CELL_TYPE_COARSE" = 'Epithelial'
      AND "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" = '74-year-old human stage'
      AND "SEX" IN ('female','male')
)

SELECT
    "FEATURE_NAME"                                AS "Gene",
    AVG(CASE WHEN "SEX" = 'female' THEN "X_VALUE" END) AS "Female_Avg_X_value",
    AVG(CASE WHEN "SEX" = 'male'   THEN "X_VALUE" END) AS "Male_Avg_X_value",
    AVG(CASE WHEN "SEX" = 'female' THEN "X_VALUE" END)
      - AVG(CASE WHEN "SEX" = 'male' THEN "X_VALUE" END) AS "Difference_FemaleMinusMale"
FROM filtered
GROUP BY "FEATURE_NAME"
HAVING COUNT(DISTINCT "SEX") = 2   -- ensure gene is expressed in both sexes
ORDER BY ABS("Difference_FemaleMinusMale") DESC NULLS LAST
LIMIT 20;