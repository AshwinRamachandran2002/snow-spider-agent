SELECT
  "b"."chromosome" AS "Chromosome",
  "b"."cytoband_name" AS "Cytoband",
  SUM(CASE WHEN "s"."copy_number" > 3 THEN 1 ELSE 0 END) AS "Amplifications",
  SUM(CASE WHEN "s"."copy_number" = 3 THEN 1 ELSE 0 END) AS "Gains",
  SUM(CASE WHEN "s"."copy_number" = 0 THEN 1 ELSE 0 END) AS "Homozygous_Deletions",
  SUM(CASE WHEN "s"."copy_number" = 1 THEN 1 ELSE 0 END) AS "Heterozygous_Deletions",
  SUM(CASE WHEN "s"."copy_number" = 2 THEN 1 ELSE 0 END) AS "Normal_Copy_States"
FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" AS "s"
JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" AS "b"
  ON "s"."chromosome" = "b"."chromosome"
  AND "s"."end_pos" >= "b"."hg38_start"
  AND "s"."start_pos" <= "b"."hg38_stop"
WHERE "s"."project_short_name" = 'TCGA-KIRC'
GROUP BY "b"."chromosome", "b"."cytoband_name"
ORDER BY "b"."chromosome", "b"."cytoband_name";