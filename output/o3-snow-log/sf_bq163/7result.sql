WITH gender_avg AS (
    SELECT
        "FEATURE_NAME",
        "SEX",
        AVG("X_VALUE") AS avg_x
    FROM HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
    WHERE "CLUSTERS" = '41'
      AND "DEVELOPMENT_STAGE" = '74-year-old human stage'
      AND "CELL_TYPE_COARSE" = 'Epithelial'
      AND "SEX" IN ('female','male')
    GROUP BY "FEATURE_NAME","SEX"
),
pivot AS (
    SELECT
        "FEATURE_NAME",
        MAX(CASE WHEN "SEX" = 'female' THEN avg_x END) AS female_avg,
        MAX(CASE WHEN "SEX" = 'male' THEN avg_x END) AS male_avg
    FROM gender_avg
    GROUP BY "FEATURE_NAME"
),
diffs AS (
    SELECT
        "FEATURE_NAME",
        female_avg,
        male_avg,
        female_avg - male_avg AS diff
    FROM pivot
    WHERE female_avg IS NOT NULL
      AND male_avg IS NOT NULL
)
SELECT
    "FEATURE_NAME",
    ROUND(diff,4) AS diff
FROM diffs
ORDER BY diff DESC NULLS LAST
LIMIT 20;