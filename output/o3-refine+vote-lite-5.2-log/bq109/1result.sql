WITH chol_studies AS (
  SELECT
    study_id
  FROM
    `open-targets-genetics.genetics.studies`
  WHERE
    LOWER(trait_reported) LIKE '%lesterol levels%'
),
filtered AS (
  SELECT
    vdc.coloc_log2_h4_h3,
    vdc.right_study
  FROM
    `open-targets-genetics.genetics.variant_disease_coloc` AS vdc
  LEFT JOIN chol_studies AS cs_left
    ON cs_left.study_id = vdc.left_study
  LEFT JOIN chol_studies AS cs_right
    ON cs_right.study_id = vdc.right_study
  WHERE
        vdc.right_gene_id      = 'ENSG00000169174'
    AND vdc.coloc_h4           > 0.8
    AND vdc.coloc_h3           < 0.02
    AND vdc.right_bio_feature  = 'IPSC'
    AND vdc.left_chrom         = '1'
    AND vdc.left_pos           = 55029009
    AND vdc.left_ref           = 'C'
    AND vdc.left_alt           = 'T'
    AND (cs_left.study_id IS NOT NULL OR cs_right.study_id IS NOT NULL)
)

SELECT
  AVG(coloc_log2_h4_h3)                                   AS avg_log2_h4_h3,
  VAR_POP(coloc_log2_h4_h3)                               AS var_log2_h4_h3,
  MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)           AS range_log2_h4_h3,
  (SELECT right_study
   FROM filtered
   ORDER BY coloc_log2_h4_h3 DESC
   LIMIT 1)                                               AS qtl_source_right_study_max_log2
FROM filtered;