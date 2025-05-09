SELECT
    "FEATURE_NAME",
    AVG(CASE WHEN "SEX" = 'female' THEN "X_VALUE" END)                         AS "AVG_FEMALE_X_VALUE",
    AVG(CASE WHEN "SEX" = 'male'   THEN "X_VALUE" END)                         AS "AVG_MALE_X_VALUE",
    AVG(CASE WHEN "SEX" = 'female' THEN "X_VALUE" END)
      - AVG(CASE WHEN "SEX" = 'male' THEN "X_VALUE" END)                       AS "DIFFERENCE_FEMALE_MINUS_MALE"
FROM
    HTAN_2.HTAN.SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT
WHERE
    "CELL_TYPE_COARSE"   = 'Epithelial'      -- only epithelial cells
    AND "CLUSTERS"       = '41'              -- cluster 41
    AND "DEVELOPMENT_STAGE" = '74-year-old human stage'  -- 74-year-old patients
GROUP BY
    "FEATURE_NAME"
HAVING
    AVG(CASE WHEN "SEX" = 'female' THEN "X_VALUE" END) IS NOT NULL
    AND AVG(CASE WHEN "SEX" = 'male'   THEN "X_VALUE" END) IS NOT NULL
ORDER BY
    "DIFFERENCE_FEMALE_MINUS_MALE" DESC NULLS LAST
LIMIT 20;