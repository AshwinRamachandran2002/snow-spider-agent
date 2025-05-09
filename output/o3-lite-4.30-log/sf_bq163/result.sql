SELECT
    "FEATURE_NAME"                                                                                                           AS "gene",
    ROUND(AVG(CASE WHEN "SEX_ONTOLOGY_TERM_ID" = 'PATO:0000383' THEN "X_VALUE" END), 4)                                      AS "avg_female",
    ROUND(AVG(CASE WHEN "SEX_ONTOLOGY_TERM_ID" = 'PATO:0000384' THEN "X_VALUE" END), 4)                                      AS "avg_male",
    ROUND(
        AVG(CASE WHEN "SEX_ONTOLOGY_TERM_ID" = 'PATO:0000383' THEN "X_VALUE" END)
      - AVG(CASE WHEN "SEX_ONTOLOGY_TERM_ID" = 'PATO:0000384' THEN "X_VALUE" END), 4)                                        AS "female_minus_male"
FROM "HTAN_2"."HTAN"."SCRNASEQ_MSK_SCLC_COMBINED_SAMPLES_CURRENT"
WHERE TRIM("CLUSTERS") = '41'
  AND "CELL_TYPE_COARSE" = 'Epithelial'
  AND "DEVELOPMENT_STAGE" ILIKE '74-year-old%'                 -- 74‑year‑old human stage
GROUP BY "FEATURE_NAME"
HAVING COUNT(CASE WHEN "SEX_ONTOLOGY_TERM_ID" = 'PATO:0000383' THEN 1 END) > 0
   AND COUNT(CASE WHEN "SEX_ONTOLOGY_TERM_ID" = 'PATO:0000384' THEN 1 END) > 0
ORDER BY "female_minus_male" DESC NULLS LAST, "gene"
LIMIT 20;