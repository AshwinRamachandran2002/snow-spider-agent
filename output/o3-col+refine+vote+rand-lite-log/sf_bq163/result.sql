WITH avg_by_sex AS (
    SELECT
        "FEATURE_NAME",
        "SEX",
        AVG("X_VALUE") AS avg_x_value
    FROM HTAN_2.HTAN."SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT"
    WHERE
        "CLUSTERS" = '41'
        AND "CELL_TYPE" ILIKE '%epithelial%'
        AND "DEVELOPMENT_STAGE" ILIKE '%74-year-old%'
        AND "SEX" IN ('female', 'male')
    GROUP BY
        "FEATURE_NAME",
        "SEX"
),
pivoted AS (
    SELECT
        f."FEATURE_NAME",
        f.avg_x_value AS female_avg_x_value,
        m.avg_x_value AS male_avg_x_value,
        f.avg_x_value - m.avg_x_value AS diff_female_minus_male
    FROM avg_by_sex f
    JOIN avg_by_sex m
        ON f."FEATURE_NAME" = m."FEATURE_NAME"
    WHERE
        f."SEX" = 'female'
        AND m."SEX" = 'male'
)
SELECT
    "FEATURE_NAME",
    female_avg_x_value,
    male_avg_x_value,
    diff_female_minus_male
FROM pivoted
ORDER BY
    diff_female_minus_male DESC NULLS LAST
LIMIT 20;