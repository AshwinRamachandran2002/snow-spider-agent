WITH filtered AS (
  SELECT
    v.coloc_log2_h4_h3,
    v.right_study,
    s.trait_reported
  FROM
    `open-targets-genetics.genetics.variant_disease_coloc` AS v
  JOIN
    `open-targets-genetics.genetics.studies` AS s
  ON
    v.left_study = s.study_id
  WHERE
        -- variant filter (left variant = 1_55029009_C_T)
        v.left_chrom = '1'
    AND v.left_pos  = 55029009
    AND v.left_ref  = 'C'
    AND v.left_alt  = 'T'
        -- gene / coloc quality filters
    AND v.right_gene_id = 'ENSG00000169174'
    AND v.coloc_h4  > 0.8
    AND v.coloc_h3  < 0.02
        -- biological feature filter
    AND v.right_bio_feature = 'IPSC'
        -- reported‑trait filter (case‑insensitive “lesterol levels”)
    AND LOWER(s.trait_reported) LIKE '%lesterol levels%'
)

SELECT
  AVG(coloc_log2_h4_h3)                                          AS avg_log2_h4_h3,
  VAR_SAMP(coloc_log2_h4_h3)                                     AS var_log2_h4_h3,
  MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)                  AS max_minus_min_log2_h4_h3,
  (SELECT right_study
     FROM filtered
     ORDER BY coloc_log2_h4_h3 DESC
     LIMIT 1)                                                    AS right_study_of_max
FROM filtered;