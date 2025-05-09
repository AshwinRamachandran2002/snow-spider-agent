WITH female AS (
    SELECT
        "FEATURE_NAME",
        AVG("X_VALUE") AS avg_female
    FROM HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
    WHERE "CELL_TYPE" ILIKE '%epithelial%'
      AND "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" ILIKE '%74-year-old%'
      AND "SEX" = 'female'
    GROUP BY "FEATURE_NAME"
),
male AS (
    SELECT
        "FEATURE_NAME",
        AVG("X_VALUE") AS avg_male
    FROM HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
    WHERE "CELL_TYPE" ILIKE '%epithelial%'
      AND "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" ILIKE '%74-year-old%'
      AND "SEX" = 'male'
    GROUP BY "FEATURE_NAME"
)
SELECT
    f."FEATURE_NAME",
    (f.avg_female - m.avg_male) AS female_minus_male_diff
FROM female f
JOIN male  m USING ("FEATURE_NAME")
ORDER BY female_minus_male_diff DESC NULLS LAST
LIMIT 20;