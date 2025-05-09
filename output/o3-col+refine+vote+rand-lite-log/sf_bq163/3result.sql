WITH avg_per_sex AS (
    SELECT
        "FEATURE_NAME",
        "SEX",
        AVG("X_VALUE") AS avg_x_value
    FROM "HTAN_2"."HTAN"."SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT"
    WHERE "CLUSTERS" = '41'
      AND "CELL_TYPE" ILIKE '%epithelial%'
      AND "DEVELOPMENT_STAGE" ILIKE '%74-year%'
      AND "SEX" IN ('female', 'male')
    GROUP BY "FEATURE_NAME", "SEX"
),
pivoted AS (
    SELECT
        "FEATURE_NAME",
        MAX(CASE WHEN "SEX" = 'female' THEN avg_x_value END) AS avg_female,
        MAX(CASE WHEN "SEX" = 'male'   THEN avg_x_value END) AS avg_male
    FROM avg_per_sex
    GROUP BY "FEATURE_NAME"
),
differences AS (
    SELECT
        "FEATURE_NAME",
        ROUND(avg_female, 4)                  AS "avg_female",
        ROUND(avg_male,   4)                  AS "avg_male",
        ROUND(avg_female - avg_male, 4)       AS diff_female_minus_male
    FROM pivoted
    WHERE avg_female IS NOT NULL
      AND avg_male   IS NOT NULL
)
SELECT *
FROM differences
ORDER BY diff_female_minus_male DESC NULLS LAST
LIMIT 20;