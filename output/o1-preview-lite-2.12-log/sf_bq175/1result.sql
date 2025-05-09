SELECT "cytoband_name"
FROM (
  SELECT c."cytoband_name",
         SUM(CASE WHEN s."copy_number" > 3 THEN 1 ELSE 0 END) AS "amplification_count",
         SUM(CASE WHEN s."copy_number" = 3 THEN 1 ELSE 0 END) AS "gain_count",
         SUM(CASE WHEN s."copy_number" = 1 THEN 1 ELSE 0 END) AS "het_deletion_count",
         RANK() OVER (ORDER BY SUM(CASE WHEN s."copy_number" > 3 THEN 1 ELSE 0 END) DESC NULLS LAST) AS "amp_rank",
         RANK() OVER (ORDER BY SUM(CASE WHEN s."copy_number" = 3 THEN 1 ELSE 0 END) DESC NULLS LAST) AS "gain_rank",
         RANK() OVER (ORDER BY SUM(CASE WHEN s."copy_number" = 1 THEN 1 ELSE 0 END) DESC NULLS LAST) AS "het_del_rank"
  FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
  JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
    ON s."chromosome" = c."chromosome"
   AND s."start_pos" <= c."hg38_stop"
   AND s."end_pos" >= c."hg38_start"
  WHERE s."project_short_name" = 'TCGA-KIRC'
    AND s."chromosome" = 'chr1'
  GROUP BY c."cytoband_name"
) ranked_cytobands
WHERE "amp_rank" <= 11 AND "gain_rank" <= 11 AND "het_del_rank" <= 11;