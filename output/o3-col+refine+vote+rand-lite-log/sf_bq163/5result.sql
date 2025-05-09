WITH female AS (
    SELECT 
        "FEATURE_NAME",
        AVG("X_VALUE") AS avg_female
    FROM "HTAN_2"."HTAN"."SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT"
    WHERE "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" ILIKE '%74-year-old%'
      AND "CELL_TYPE" ILIKE '%epithelial%'
      AND "SEX" ILIKE 'female'
    GROUP BY "FEATURE_NAME"
),
male AS (
    SELECT 
        "FEATURE_NAME",
        AVG("X_VALUE") AS avg_male
    FROM "HTAN_2"."HTAN"."SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT"
    WHERE "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" ILIKE '%74-year-old%'
      AND "CELL_TYPE" ILIKE '%epithelial%'
      AND "SEX" ILIKE 'male'
    GROUP BY "FEATURE_NAME"
)
SELECT 
    f."FEATURE_NAME",
    ROUND(f.avg_female - m.avg_male, 4) AS female_minus_male
FROM female f
JOIN male  m USING ("FEATURE_NAME")
ORDER BY female_minus_male DESC NULLS LAST
LIMIT 20;