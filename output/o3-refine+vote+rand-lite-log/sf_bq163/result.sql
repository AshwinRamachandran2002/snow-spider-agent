WITH filtered AS (
    SELECT
        feature_name AS gene,
        sex,
        x_value
    FROM HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
    WHERE clusters = 41
      AND development_stage = '74-year-old human stage'
      AND cell_type_coarse = 'Epithelial'
      AND sex IN ('female','male')
),
avg_by_sex AS (
    SELECT
        gene,
        AVG(CASE WHEN sex = 'female' THEN x_value END) AS avg_female,
        AVG(CASE WHEN sex = 'male'   THEN x_value END) AS avg_male
    FROM filtered
    GROUP BY gene
),
diffs AS (
    SELECT
        gene,
        avg_female - avg_male AS diff_female_minus_male
    FROM avg_by_sex
    WHERE avg_female IS NOT NULL
      AND avg_male   IS NOT NULL
)
SELECT
    gene,
    diff_female_minus_male
FROM diffs
ORDER BY diff_female_minus_male DESC NULLS LAST,
         gene
LIMIT 20;