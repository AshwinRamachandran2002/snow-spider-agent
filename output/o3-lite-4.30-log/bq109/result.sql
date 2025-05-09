SELECT
  ROUND(AVG(vc.coloc_log2_h4_h3),4)                                                AS average_log2h4_over_h3,
  ROUND(VAR_POP(vc.coloc_log2_h4_h3),4)                                            AS variance_log2h4_over_h3,
  ROUND(MAX(vc.coloc_log2_h4_h3) - MIN(vc.coloc_log2_h4_h3),4)                     AS max_minus_min_log2h4_over_h3,
  ARRAY_AGG(vc.right_study ORDER BY vc.coloc_log2_h4_h3 DESC LIMIT 1)[OFFSET(0)]   AS qtl_source
FROM `open-targets-genetics.genetics.variant_disease_coloc` AS vc
JOIN `open-targets-genetics.genetics.studies`               AS s
  ON vc.left_study = s.study_id
WHERE vc.right_gene_id = 'ENSG00000169174'
  AND vc.coloc_h4  > 0.8
  AND vc.coloc_h3  < 0.02
  AND vc.right_bio_feature = 'IPSC'
  AND LOWER(s.trait_reported) LIKE '%lesterol levels%'
  AND (
        CONCAT(vc.left_chrom,'_',CAST(vc.left_pos AS STRING),'_',vc.left_ref,'_',vc.left_alt)  = '1_55029009_C_T'
     OR CONCAT(vc.right_chrom,'_',CAST(vc.right_pos AS STRING),'_',vc.right_ref,'_',vc.right_alt) = '1_55029009_C_T'
      );