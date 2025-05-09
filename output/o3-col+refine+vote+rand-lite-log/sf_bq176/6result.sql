--  Identify TCGA-LAML cases with the highest length-weighted average
--  copy-number (segment_mean) across cytoband 15q11 on chromosome 15
WITH cytoband_bounds AS (          -- hg38 coordinate span of 15q11
    SELECT  MIN("hg38_start") AS "region_start",
            MAX("hg38_stop")  AS "region_end"
    FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" ILIKE '15q11%'
),
overlapping_segs AS (              -- segments that overlap that span
    SELECT  s."case_barcode",
            GREATEST(s."start_pos", cb."region_start") AS "ov_start",
            LEAST(  s."end_pos",   cb."region_end")   AS "ov_end",
            s."segment_mean"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02" s
    JOIN cytoband_bounds cb
      ON s."end_pos"   >= cb."region_start"
     AND s."start_pos" <= cb."region_end"
    WHERE s."project_short_name" = 'TCGA-LAML'
      AND s."chromosome" = '15'
),
weighted_avg AS (                  -- length-weighted average per case
    SELECT  "case_barcode",
            SUM( ("ov_end" - "ov_start" + 1) * "segment_mean") /
            SUM(  "ov_end" - "ov_start" + 1)                  AS "weighted_avg_copy_number"
    FROM overlapping_segs
    GROUP BY "case_barcode"
)
SELECT  "case_barcode",
        ROUND("weighted_avg_copy_number", 4) AS "weighted_avg_copy_number"
FROM    weighted_avg
ORDER BY "weighted_avg_copy_number" DESC NULLS LAST
LIMIT 20;