WITH filtered AS (
  SELECT
    c.coloc_log2_h4_h3,
    c.right_study
  FROM `open-targets-genetics.genetics.variant_disease_coloc` AS c
  JOIN `open-targets-genetics.genetics.studies`              AS s
    ON c.left_study = s.study_id
  WHERE c.right_gene_id      = 'ENSG00000169174'
    AND c.coloc_h4           > 0.8
    AND c.coloc_h3           < 0.02
    AND LOWER(s.trait_reported) LIKE '%lesterol levels%'
    AND c.right_bio_feature  = 'IPSC'
    AND c.left_chrom = '1'  AND c.left_pos = 55029009
    AND c.left_ref  = 'C'   AND c.left_alt = 'T'
)

SELECT
  AVG(coloc_log2_h4_h3)                                   AS avg_log2_h4_h3,
  VAR_POP(coloc_log2_h4_h3)                               AS var_log2_h4_h3,
  MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)           AS max_min_diff_log2_h4_h3,
  (SELECT right_study
     FROM filtered
     ORDER BY coloc_log2_h4_h3 DESC
     LIMIT 1)                                             AS right_study_of_max_log2_h4_h3
FROM filtered;