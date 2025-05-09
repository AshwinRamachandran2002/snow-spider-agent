WITH filtered AS (
  SELECT
    c.coloc_log2_h4_h3,
    c.right_study
  FROM `open-targets-genetics.genetics.variant_disease_coloc` AS c
  JOIN `open-targets-genetics.genetics.studies`               AS s
    ON c.left_study = s.study_id
  WHERE c.right_gene_id        = 'ENSG00000169174'
    AND c.left_chrom           = '1'
    AND c.left_pos             = 55029009
    AND c.left_ref             = 'C'
    AND c.left_alt             = 'T'
    AND c.coloc_h4            > 0.8
    AND c.coloc_h3            < 0.02
    AND c.right_bio_feature    = 'IPSC'
    AND LOWER(s.trait_reported) LIKE '%lesterol levels%'
)
SELECT
  AVG(coloc_log2_h4_h3)                                        AS avg_log2,
  VAR_SAMP(coloc_log2_h4_h3)                                   AS var_log2,
  MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)                AS range_log2,
  ARRAY_AGG(right_study ORDER BY coloc_log2_h4_h3 DESC LIMIT 1)[OFFSET(0)]
                                                               AS qtl_source_max
FROM filtered;