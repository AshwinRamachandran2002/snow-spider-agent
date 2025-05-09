WITH filtered AS (
  SELECT
    vc.right_study,
    vc.coloc_log2_h4_h3
  FROM `open-targets-genetics.genetics.variant_disease_coloc` AS vc
  JOIN `open-targets-genetics.genetics.studies`               AS st
    ON vc.left_study = st.study_id
  WHERE vc.right_gene_id = 'ENSG00000169174'
    AND vc.left_chrom = '1'
    AND vc.left_pos   = 55029009
    AND vc.left_ref   = 'C'
    AND vc.left_alt   = 'T'
    AND vc.coloc_h4  > 0.8
    AND vc.coloc_h3  < 0.02
    AND vc.right_bio_feature = 'IPSC'
    AND LOWER(COALESCE(st.trait_reported, '')) LIKE '%lesterol levels%'
)
SELECT
  ROUND(AVG(coloc_log2_h4_h3), 4)                                AS average_log2h4_over_h3,
  ROUND(VAR_SAMP(coloc_log2_h4_h3), 4)                           AS variance_log2h4_over_h3,
  ROUND(MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3), 4)        AS max_minus_min_log2h4_over_h3,
  (SELECT right_study FROM filtered ORDER BY coloc_log2_h4_h3 DESC LIMIT 1) 
                                                                  AS qtl_source
FROM filtered;