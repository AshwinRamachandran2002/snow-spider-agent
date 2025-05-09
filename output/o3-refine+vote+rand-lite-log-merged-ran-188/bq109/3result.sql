WITH filtered AS (
  SELECT
    vdc.coloc_log2_h4_h3,
    vdc.right_study
  FROM `open-targets-genetics.genetics.variant_disease_coloc` AS vdc
  JOIN `open-targets-genetics.genetics.studies`              AS st
    ON vdc.left_study = st.study_id
  WHERE vdc.right_gene_id      = 'ENSG00000169174'
    AND vdc.coloc_h4           > 0.8
    AND vdc.coloc_h3           < 0.02
    AND vdc.right_bio_feature  = 'IPSC'
    AND vdc.left_chrom         = '1'
    AND vdc.left_pos           = 55029009
    AND vdc.left_ref           = 'C'
    AND vdc.left_alt           = 'T'
    AND LOWER(st.trait_reported) LIKE '%lesterol levels%'   -- e.g. "cholesterol levels"
)

SELECT
  AVG(coloc_log2_h4_h3)                                   AS avg_log2_h4_h3,
  VAR_POP(coloc_log2_h4_h3)                               AS var_log2_h4_h3,
  MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)           AS max_min_diff,
  (SELECT right_study
     FROM filtered
     ORDER BY coloc_log2_h4_h3 DESC
     LIMIT 1)                                             AS qtl_source_of_max
FROM filtered;