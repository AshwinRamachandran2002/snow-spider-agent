/* Identify TCGA-LAML case(s) with the highest weighted-average absolute copy number
   in cytoband 15q11 on chromosome 15                                         */

WITH band AS (   -- exact hg38 coordinates of cytoband 15q11
  SELECT "hg38_start", "hg38_stop"
  FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
  WHERE "chromosome" = 'chr15'
    AND "cytoband_name" = '15q11'
),

segments AS (    -- CN segments that overlap the cytoband
  SELECT
    s."case_barcode",
    GREATEST(s."start_pos",  b."hg38_start")               AS "ovl_start",
    LEAST(  s."end_pos",     b."hg38_stop")                AS "ovl_end",
    2 * POWER(2, s."segment_mean")                         AS "abs_cn"   -- absolute CN
  FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14" s
  CROSS JOIN band b
  WHERE s."project_short_name" = 'TCGA-LAML'
    AND s."chromosome" = '15'
    AND s."end_pos"   >= b."hg38_start"
    AND s."start_pos" <= b."hg38_stop"
),

weighted AS (    -- length-weighted average abs CN per case
  SELECT
    "case_barcode",
    SUM( ("ovl_end" - "ovl_start" + 1) * "abs_cn")
      / SUM("ovl_end" - "ovl_start" + 1)                  AS "weighted_avg_cn"
  FROM segments
  GROUP BY "case_barcode"
),

max_cn AS (       -- maximum weighted average among all cases
  SELECT MAX("weighted_avg_cn") AS "max_cn"
  FROM weighted
)

SELECT w."case_barcode",
       w."weighted_avg_cn"
FROM   weighted  w
JOIN   max_cn    m  ON w."weighted_avg_cn" = m."max_cn"
ORDER BY w."case_barcode";