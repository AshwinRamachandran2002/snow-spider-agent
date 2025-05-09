-- Average, variance, range of log2(H4/H3) and the QTL source
-- for the specified gene / variant / bio-feature / trait filters
WITH coloc_filtered AS (
  SELECT
    vdc.coloc_log2_h4_h3,
    vdc.right_study
  FROM `open-targets-genetics.genetics.variant_disease_coloc` AS vdc
  JOIN `open-targets-genetics.genetics.studies`                AS st
    ON vdc.left_study = st.study_id
  WHERE vdc.right_gene_id = 'ENSG00000169174'
    AND vdc.coloc_h4  > 0.8
    AND vdc.coloc_h3  < 0.02
    AND vdc.right_bio_feature = 'IPSC'
    AND CONCAT(vdc.left_chrom,'_',vdc.left_pos,'_',vdc.left_ref,'_',vdc.left_alt)
        = '1_55029009_C_T'
    AND LOWER(st.trait_reported) LIKE '%lesterol levels%'      -- e.g. “cholesterol levels”
)

SELECT
  AVG(coloc_log2_h4_h3)                                   AS avg_log2,
  VAR_POP(coloc_log2_h4_h3)                               AS var_log2,
  MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)           AS range_log2,
  (SELECT right_study
   FROM   coloc_filtered
   ORDER  BY coloc_log2_h4_h3 DESC
   LIMIT  1)                                              AS right_study_max
FROM coloc_filtered;