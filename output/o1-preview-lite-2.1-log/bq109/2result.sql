WITH filtered_data AS (
    SELECT vd.right_study, vd.coloc_log2_h4_h3
    FROM `open-targets-genetics.genetics.variant_disease_coloc` AS vd
    JOIN `open-targets-genetics.genetics.studies` AS s
      ON vd.left_study = s.study_id
    WHERE vd.right_gene_id = 'ENSG00000169174'
      AND vd.coloc_h4 > 0.8
      AND vd.coloc_h3 < 0.02
      AND vd.right_bio_feature = 'IPSC'
      AND vd.left_chrom = '1'
      AND vd.left_pos = 55029009
      AND vd.left_ref = 'C'
      AND vd.left_alt = 'T'
      AND LOWER(s.trait_reported) LIKE '%lesterol levels%'
), stats AS (
    SELECT
      AVG(coloc_log2_h4_h3) AS Average_log2_h4_h3,
      VAR_SAMP(coloc_log2_h4_h3) AS Variance_log2_h4_h3,
      (MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)) AS Max_min_difference_log2_h4_h3,
      MAX(coloc_log2_h4_h3) AS Max_coloc_log2_h4_h3
    FROM filtered_data
)
SELECT
    ROUND(stats.Average_log2_h4_h3, 4) AS Average_log2_h4_h3,
    ROUND(stats.Variance_log2_h4_h3, 4) AS Variance_log2_h4_h3,
    ROUND(stats.Max_min_difference_log2_h4_h3, 4) AS Max_min_difference_log2_h4_h3,
    fd.right_study AS QTL_source_right_study_of_max_log2_h4_h3
FROM stats
JOIN filtered_data AS fd
  ON fd.coloc_log2_h4_h3 = stats.Max_coloc_log2_h4_h3
LIMIT 1