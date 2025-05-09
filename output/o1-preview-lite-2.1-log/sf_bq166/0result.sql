WITH overlapping_segments AS (
  SELECT
    t."case_barcode",
    t."chromosome",
    c."cytoband_name" AS "Cytoband",
    t."copy_number"
  FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 t
  JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38 c
    ON t."chromosome" = c."chromosome"
    AND t."start_pos" <= c."hg38_stop"
    AND t."end_pos" >= c."hg38_start"
  WHERE t."project_short_name" = 'TCGA-KIRC'
),
max_copy_numbers AS (
  SELECT
    "case_barcode",
    "chromosome",
    "Cytoband",
    MAX("copy_number") AS "max_copy_number"
  FROM overlapping_segments
  GROUP BY "case_barcode", "chromosome", "Cytoband"
),
frequencies AS (
  SELECT
    "chromosome" AS "Chromosome",
    "Cytoband",
    SUM(CASE WHEN "max_copy_number" > 3 THEN 1 ELSE 0 END) AS "Amplifications",
    SUM(CASE WHEN "max_copy_number" = 3 THEN 1 ELSE 0 END) AS "Gains",
    SUM(CASE WHEN "max_copy_number" = 0 THEN 1 ELSE 0 END) AS "Homozygous_Deletions",
    SUM(CASE WHEN "max_copy_number" = 1 THEN 1 ELSE 0 END) AS "Heterozygous_Deletions",
    SUM(CASE WHEN "max_copy_number" = 2 THEN 1 ELSE 0 END) AS "Normal_Diploid"
  FROM max_copy_numbers
  GROUP BY "chromosome", "Cytoband"
  ORDER BY "chromosome", "Cytoband"
)
SELECT * FROM frequencies;