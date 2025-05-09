WITH counts AS (
  SELECT
    cyto."cytoband_name",
    SUM(CASE WHEN cnv."copy_number" > 3 THEN 1 ELSE 0 END) AS "Amplification_Count",
    SUM(CASE WHEN cnv."copy_number" = 3 THEN 1 ELSE 0 END) AS "Gain_Count",
    SUM(CASE WHEN cnv."copy_number" = 1 THEN 1 ELSE 0 END) AS "Heterozygous_Deletion_Count"
  FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" AS cnv
  JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" AS cyto
    ON cnv."chromosome" = cyto."chromosome"
    AND cnv."start_pos" <= cyto."hg38_stop"
    AND cnv."end_pos" >= cyto."hg38_start"
  WHERE cnv."project_short_name" = 'TCGA-KIRC' AND cnv."chromosome" = 'chr1'
  GROUP BY cyto."cytoband_name"
),
ranked AS (
  SELECT
    "cytoband_name",
    DENSE_RANK() OVER (ORDER BY "Amplification_Count" DESC NULLS LAST) AS "Amplification_Rank",
    DENSE_RANK() OVER (ORDER BY "Gain_Count" DESC NULLS LAST) AS "Gain_Rank",
    DENSE_RANK() OVER (ORDER BY "Heterozygous_Deletion_Count" DESC NULLS LAST) AS "Het_Del_Rank"
  FROM counts
)
SELECT "cytoband_name"
FROM ranked
WHERE "Amplification_Rank" <= 11 AND "Gain_Rank" <= 11 AND "Het_Del_Rank" <= 11
ORDER BY "cytoband_name";