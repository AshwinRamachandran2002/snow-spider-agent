WITH filtered AS (
  SELECT vdc.*
  FROM `open-targets-genetics.genetics.variant_disease_coloc` AS vdc
  JOIN `open-targets-genetics.genetics.studies`               AS st
       ON vdc.left_study = st.study_id
  WHERE vdc.right_gene_id          = 'ENSG00000169174'
    AND vdc.coloc_h4              > 0.8
    AND vdc.coloc_h3              < 0.02
    AND vdc.right_bio_feature      = 'IPSC'
    AND LOWER(st.trait_reported)  LIKE '%lesterol levels%'          -- e.g. "cholesterol levels"
    AND (
          (vdc.left_chrom  = '1' AND vdc.left_pos  = 55029009
           AND vdc.left_ref = 'C' AND vdc.left_alt = 'T')
       OR (vdc.right_chrom = '1' AND vdc.right_pos = 55029009
           AND vdc.right_ref = 'C' AND vdc.right_alt = 'T')
        )
),
stats AS (
  SELECT
    AVG(coloc_log2_h4_h3)         AS avg_log2_h4_h3,
    VAR_POP(coloc_log2_h4_h3)     AS var_log2_h4_h3,
    MAX(coloc_log2_h4_h3)         AS max_log2,
    MIN(coloc_log2_h4_h3)         AS min_log2
  FROM filtered
),
max_row AS (
  SELECT
    right_study AS right_study_max_log2_h4_h3
  FROM filtered
  ORDER BY coloc_log2_h4_h3 DESC
  LIMIT 1
)
SELECT
  s.avg_log2_h4_h3,
  s.var_log2_h4_h3,
  s.max_log2 - s.min_log2        AS max_min_diff_log2_h4_h3,
  m.right_study_max_log2_h4_h3
FROM stats s
CROSS JOIN max_row m;