-- Average, variance, range of log2(H4/H3) and QTL study with the maximal value
WITH filtered AS (
  SELECT
    c.coloc_log2_h4_h3,
    c.right_study
  FROM  `open-targets-genetics.genetics.variant_disease_coloc` AS c
  JOIN  `open-targets-genetics.genetics.studies`              AS s
    ON s.study_id = c.left_study
  WHERE c.right_gene_id = 'ENSG00000169174'
    AND c.left_chrom    = '1'
    AND c.left_pos      = 55029009
    AND c.left_ref      = 'C'
    AND c.left_alt      = 'T'
    AND c.coloc_h4     > 0.80
    AND c.coloc_h3     < 0.02
    AND LOWER(c.right_bio_feature) LIKE '%ipsc%'
    AND LOWER(s.trait_reported)    LIKE '%lesterol levels%'
)
SELECT
  AVG(coloc_log2_h4_h3)                                AS avg_log2_h4_h3,
  VAR_POP(coloc_log2_h4_h3)                            AS var_log2_h4_h3,
  MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)        AS range_log2_h4_h3,
  (SELECT right_study
     FROM filtered
     ORDER BY coloc_log2_h4_h3 DESC
     LIMIT 1)                                          AS qtl_source_max_log2
FROM filtered;