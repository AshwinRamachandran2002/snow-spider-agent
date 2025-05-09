WITH filtered AS (
  SELECT
    v.coloc_log2_h4_h3,
    v.right_study
  FROM `open-targets-genetics.genetics.variant_disease_coloc` AS v
  JOIN `open-targets-genetics.genetics.studies`              AS st
    ON v.left_study = st.study_id
  WHERE v.right_gene_id        = 'ENSG00000169174'
    AND v.coloc_h4             > 0.8
    AND v.coloc_h3             < 0.02
    AND v.right_bio_feature    = 'IPSC'
    AND LOWER(st.trait_reported) LIKE '%lesterol levels%'
    AND v.left_chrom = '1'
    AND v.left_pos   = 55029009
    AND v.left_ref   = 'C'
    AND v.left_alt   = 'T'
)
SELECT
  ROUND(AVG(coloc_log2_h4_h3), 4)                               AS average_log2h4_over_h3,
  ROUND(VAR_SAMP(coloc_log2_h4_h3), 4)                          AS variance_log2h4_over_h3,
  ROUND(MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3), 4)       AS max_minus_min_log2h4_over_h3,
  (SELECT right_study
     FROM filtered
     ORDER BY coloc_log2_h4_h3 DESC
     LIMIT 1)                                                   AS qtl_source
FROM filtered;