WITH per_sex AS (
  SELECT
      "FEATURE_NAME",
      "SEX",
      AVG("X_VALUE") AS avg_x
  FROM HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
  WHERE
      "CELL_TYPE" = 'epithelial cell'
      AND "CLUSTERS" = 41
      AND "DEVELOPMENT_STAGE" = '74-year-old human stage'
      AND "SEX" IN ('female','male')
  GROUP BY
      "FEATURE_NAME",
      "SEX"
),
pivoted AS (
  SELECT
      p_f."FEATURE_NAME",
      p_f.avg_x AS female_avg,
      p_m.avg_x AS male_avg,
      (p_f.avg_x - p_m.avg_x) AS diff_female_minus_male
  FROM  per_sex p_f
  JOIN  per_sex p_m
        ON p_f."FEATURE_NAME" = p_m."FEATURE_NAME"
       AND p_f."SEX" = 'female'
       AND p_m."SEX" = 'male'
)
SELECT
    "FEATURE_NAME",
    diff_female_minus_male AS difference_female_minus_male
FROM pivoted
ORDER BY
    diff_female_minus_male DESC NULLS LAST,
    "FEATURE_NAME"
LIMIT 20;