-- Compute summary statistics and the QTL source that gives the
-- largest log₂(h4/h3) for the requested colocalisation record
WITH filt AS (
  SELECT
    vc.coloc_log2_h4_h3,
    vc.right_study                          AS qtl_source
  FROM `open-targets-genetics.genetics.variant_disease_coloc` AS vc
  JOIN `open-targets-genetics.genetics.variant_disease`       AS vd
    ON vd.study_id = vc.left_study
  WHERE vc.right_gene_id      = 'ENSG00000169174'
    AND vc.right_bio_feature  = 'IPSC'
    AND vc.coloc_h4          > 0.8
    AND vc.coloc_h3          < 0.02
    AND vc.left_chrom         = '1'
    AND vc.left_pos           = 55029009
    AND vc.left_ref           = 'C'
    AND vc.left_alt           = 'T'
    AND LOWER(vd.trait_reported) LIKE '%lesterol levels%'
)

SELECT
  AVG(coloc_log2_h4_h3)                           AS avg_log2_h4_h3,
  VAR_SAMP(coloc_log2_h4_h3)                      AS var_log2_h4_h3,
  MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)   AS range_log2_h4_h3,
  ARRAY_AGG(
      STRUCT(qtl_source, coloc_log2_h4_h3)
      ORDER BY coloc_log2_h4_h3 DESC
      LIMIT 1
  )[OFFSET(0)].qtl_source                          AS qtl_source_of_max
FROM filt;