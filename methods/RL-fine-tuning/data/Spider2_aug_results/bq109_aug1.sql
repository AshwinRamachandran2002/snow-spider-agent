-- Task: Find the average log2(h4/h3) where right gene id is "ENSG00000169174", h4 > 0.8, h3 < 0.02, reported trait includes "lesterol levels", right biological feature is "IPSC", and the variant is '1_55029009_C_T'.
SELECT
  ROUND(AVG(vdc.coloc_log2_h4_h3), 4) AS Average_log2_h4_h3
FROM
  `open-targets-genetics.genetics.variant_disease_coloc` AS vdc
JOIN
  `open-targets-genetics.genetics.studies` AS s ON vdc.left_study = s.study_id
WHERE
  vdc.right_gene_id = 'ENSG00000169174'
  AND vdc.coloc_h4 > 0.8
  AND vdc.coloc_h3 < 0.02
  AND LOWER(s.trait_reported) LIKE '%lesterol levels%'
  AND vdc.right_bio_feature = 'IPSC'
  AND vdc.left_chrom = '1'
  AND vdc.left_pos = 55029009
  AND vdc.left_ref = 'C'
  AND vdc.left_alt = 'T';