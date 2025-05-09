SELECT
  AVG(c.coloc_log2_h4_h3)                                   AS avg_log2_h4_h3,
  VAR_SAMP(c.coloc_log2_h4_h3)                              AS var_log2_h4_h3,
  MAX(c.coloc_log2_h4_h3) - MIN(c.coloc_log2_h4_h3)         AS range_log2_h4_h3,
  ARRAY_AGG(STRUCT(c.right_study, c.coloc_log2_h4_h3)
            ORDER BY c.coloc_log2_h4_h3 DESC
            LIMIT 1)[OFFSET(0)].right_study                AS right_study_max_log2
FROM   `open-targets-genetics.genetics.variant_disease_coloc` AS c
JOIN   `open-targets-genetics.genetics.studies`               AS s
  ON   c.left_study = s.study_id
WHERE  c.right_gene_id = 'ENSG00000169174'
  AND  c.coloc_h4  > 0.80
  AND  c.coloc_h3  < 0.02
  AND  LOWER(c.right_bio_feature) = 'ipsc'
  AND  c.left_chrom = '1'
  AND  c.left_pos   = 55029009
  AND  c.left_ref   = 'C'
  AND  c.left_alt   = 'T'
  AND  LOWER(s.trait_reported) LIKE '%lesterol levels%';