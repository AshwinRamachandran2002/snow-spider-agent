WITH filtered AS (
    SELECT
        "FEATURE_NAME",
        "SEX",
        "X_VALUE"
    FROM HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
    WHERE "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" = '74-year-old human stage'
      AND "CELL_TYPE_COARSE" = 'Epithelial'
      AND "SEX" IN ('female','male')
),
sex_avgs AS (
    SELECT
        "FEATURE_NAME",
        AVG(CASE WHEN "SEX" = 'female' THEN "X_VALUE" END) AS female_avg_x_value,
        AVG(CASE WHEN "SEX" = 'male'   THEN "X_VALUE" END) AS male_avg_x_value
    FROM filtered
    GROUP BY "FEATURE_NAME"
),
diffs AS (
    SELECT
        "FEATURE_NAME",
        female_avg_x_value,
        male_avg_x_value,
        female_avg_x_value - male_avg_x_value AS difference
    FROM sex_avgs
    WHERE female_avg_x_value IS NOT NULL
      AND male_avg_x_value   IS NOT NULL
)
SELECT
    "FEATURE_NAME",
    ROUND(female_avg_x_value, 4) AS female_avg_x_value,
    ROUND(male_avg_x_value,   4) AS male_avg_x_value,
    ROUND(difference,         4) AS difference
FROM diffs
ORDER BY ABS(difference) DESC NULLS LAST
LIMIT 20;