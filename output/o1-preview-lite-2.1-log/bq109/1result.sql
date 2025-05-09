WITH filtered_data AS (
  SELECT
    vdc.coloc_log2_h4_h3,
    vdc.right_study
  FROM `open-targets-genetics.genetics.variant_disease_coloc` vdc
  JOIN `open-targets-genetics.genetics.studies` s ON vdc.left_study = s.study_id
  WHERE
    vdc.right_gene_id = 'ENSG00000169174'
    AND vdc.coloc_h4 > 0.8
    AND vdc.coloc_h3 < 0.02
    AND LOWER(s.trait_reported) LIKE '%lesterol levels%'
    AND vdc.right_bio_feature = 'IPSC'
    AND vdc.left_chrom = '1'
    AND vdc.left_pos = 55029009
    AND vdc.left_ref = 'C'
    AND vdc.left_alt = 'T'
)
SELECT
  ROUND(AVG(coloc_log2_h4_h3), 4) AS Average_log2_h4_h3,
  ROUND(VAR_POP(coloc_log2_h4_h3), 4) AS Variance_log2_h4_h3,
  ROUND(MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3), 4) AS Max_min_difference_log2_h4_h3,
  (SELECT right_study FROM filtered_data
   ORDER BY coloc_log2_h4_h3 DESC
   LIMIT 1) AS QTL_source_right_study_of_max_log2_h4_h3
FROM filtered_data;