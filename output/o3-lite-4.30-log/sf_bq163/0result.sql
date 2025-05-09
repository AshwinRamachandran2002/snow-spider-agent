WITH female AS (
    SELECT
        "FEATURE_NAME",
        AVG("X_VALUE") AS "avg_female"
    FROM "HTAN_2"."HTAN"."SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT"
    WHERE "CLUSTERS" = '41'
      AND "CELL_TYPE_COARSE" = 'Epithelial'
      AND "DEVELOPMENT_STAGE" = '74-year-old human stage'
      AND "SEX" = 'female'
    GROUP BY "FEATURE_NAME"
),
male AS (
    SELECT
        "FEATURE_NAME",
        AVG("X_VALUE") AS "avg_male"
    FROM "HTAN_2"."HTAN"."SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT"
    WHERE "CLUSTERS" = '41'
      AND "CELL_TYPE_COARSE" = 'Epithelial'
      AND "DEVELOPMENT_STAGE" = '74-year-old human stage'
      AND "SEX" = 'male'
    GROUP BY "FEATURE_NAME"
)
SELECT
    f."FEATURE_NAME",
    ROUND(f."avg_female" - COALESCE(m."avg_male", 0), 4) AS "female_minus_male_avg_X"
FROM female f
LEFT JOIN male m
       ON f."FEATURE_NAME" = m."FEATURE_NAME"
ORDER BY "female_minus_male_avg_X" DESC NULLS LAST,
         f."FEATURE_NAME" ASC
LIMIT 20;