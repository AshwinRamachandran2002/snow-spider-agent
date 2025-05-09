WITH amplifications AS (
    SELECT c."cytoband_name", COUNT(DISTINCT s."sample_barcode") AS "amplification_count"
    FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
    JOIN "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02" s
      ON REPLACE(c."chromosome", 'chr', '') = s."chromosome"
     AND s."start_pos" <= c."hg38_stop"
     AND s."end_pos" >= c."hg38_start"
    WHERE s."chromosome" = '1'
      AND s."project_short_name" = 'TCGA-KIRC'
      AND s."segment_mean" >= 2  -- Threshold for amplifications
    GROUP BY c."cytoband_name"
),
amp_ranks AS (
    SELECT "cytoband_name", "amplification_count",
           RANK() OVER (ORDER BY "amplification_count" DESC NULLS LAST) AS "amplification_rank"
    FROM amplifications
),
gains AS (
    SELECT c."cytoband_name", COUNT(DISTINCT s."sample_barcode") AS "gain_count"
    FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
    JOIN "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02" s
      ON REPLACE(c."chromosome", 'chr', '') = s."chromosome"
     AND s."start_pos" <= c."hg38_stop"
     AND s."end_pos" >= c."hg38_start"
    WHERE s."chromosome" = '1'
      AND s."project_short_name" = 'TCGA-KIRC'
      AND s."segment_mean" BETWEEN 0.2 AND 2  -- Threshold for gains
    GROUP BY c."cytoband_name"
),
gain_ranks AS (
    SELECT "cytoband_name", "gain_count",
           RANK() OVER (ORDER BY "gain_count" DESC NULLS LAST) AS "gain_rank"
    FROM gains
),
deletions AS (
    SELECT c."cytoband_name", COUNT(DISTINCT s."sample_barcode") AS "deletion_count"
    FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
    JOIN "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02" s
      ON REPLACE(c."chromosome", 'chr', '') = s."chromosome"
     AND s."start_pos" <= c."hg38_stop"
     AND s."end_pos" >= c."hg38_start"
    WHERE s."chromosome" = '1'
      AND s."project_short_name" = 'TCGA-KIRC'
      AND s."segment_mean" BETWEEN -2 AND -0.2  -- Threshold for heterozygous deletions
    GROUP BY c."cytoband_name"
),
del_ranks AS (
    SELECT "cytoband_name", "deletion_count",
           RANK() OVER (ORDER BY "deletion_count" DESC NULLS LAST) AS "deletion_rank"
    FROM deletions
),
all_ranks AS (
    SELECT a."cytoband_name",
           a."amplification_rank",
           g."gain_rank",
           d."deletion_rank"
    FROM amp_ranks a
    JOIN gain_ranks g ON a."cytoband_name" = g."cytoband_name"
    JOIN del_ranks d ON a."cytoband_name" = d."cytoband_name"
)
SELECT "cytoband_name" AS "Cytoband_Name"
FROM all_ranks
WHERE "amplification_rank" <= 11 AND "gain_rank" <= 11 AND "deletion_rank" <= 11
ORDER BY "cytoband_name";