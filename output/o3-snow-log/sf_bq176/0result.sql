/* 1) get genomic coordinates of cytoband 15q11 (take entire 15q11 block, incl. sub-bands) */
WITH cyto_bounds AS (
    SELECT  MIN("hg38_start") AS region_start ,
            MAX("hg38_stop")  AS region_end
    FROM    TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE   "chromosome"      = 'chr15'
      AND   "cytoband_name"  LIKE '15q11%'        -- 15q11 plus any sub-bands (15q11.1, 15q11.2 …)
),

/* 2) pull copy-number segments for TCGA-LAML on chromosome 15
      and convert segment_mean (log2(CN/2)) back to absolute copy number */
segments AS (
    SELECT  s."case_barcode",
            s."start_pos",
            s."end_pos",
            /* absolute CN  = 2 * 2^(segment_mean) */
            2 * POWER(2 , s."segment_mean")    AS copy_number
    FROM    TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14  s
    WHERE   s."project_short_name" = 'TCGA-LAML'
      AND   s."chromosome"         = '15'
),

/* 3) keep only the portions of each segment that overlap 15q11 */
overlaps AS (
    SELECT  seg."case_barcode",
            GREATEST(seg."start_pos", cb.region_start) AS ov_start,
            LEAST  (seg."end_pos"  , cb.region_end)   AS ov_end,
            seg.copy_number
    FROM    segments seg
    CROSS   JOIN cyto_bounds cb
    WHERE   seg."end_pos"   >= cb.region_start   -- segment starts before cyto end
      AND   seg."start_pos" <= cb.region_end     -- segment ends   after cyto start
),

/* 4) weighted average CN per case within 15q11 */
case_weighted AS (
    SELECT  "case_barcode",
            SUM( (ov_end - ov_start + 1) * copy_number )              AS weighted_sum ,
            SUM(  ov_end - ov_start + 1 )                             AS total_len ,
            SUM( (ov_end - ov_start + 1) * copy_number )
            / NULLIF( SUM( ov_end - ov_start + 1 ), 0 )               AS weighted_avg_cn
    FROM    overlaps
    GROUP BY "case_barcode"
),

/* 5) find the maximal weighted average CN */
ranked AS (
    SELECT  cw.*,
            MAX(weighted_avg_cn) OVER() AS max_avg_cn
    FROM    case_weighted cw
)

/* 6) return the case barcodes that achieve the highest value */
SELECT  "case_barcode",
        ROUND(weighted_avg_cn , 4) AS weighted_avg_copy_number
FROM    ranked
WHERE   weighted_avg_cn = max_avg_cn            -- keep all ties for highest value
ORDER BY "case_barcode";