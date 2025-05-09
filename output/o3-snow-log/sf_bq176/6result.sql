/* -----------------------------------------------------------------
   1.  Get hg38 genomic coordinates for cytoband 15q11 on chr15
   2.  Pull TCGA-LAML masked copy-number segments on chromosome 15
   3.  Intersect segments with the cytoband; compute overlap length
   4.  Calculate the length-weighted average segment_mean per case
   5.  Return the case_barcode(s) that attain the global maximum
-------------------------------------------------------------------*/
WITH cytoband AS (
    SELECT
        "hg38_start"  AS cb_start,
        "hg38_stop"   AS cb_end
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" = '15q11'
),
segments AS (
    SELECT
        s."case_barcode",
        s."start_pos",
        s."end_pos",
        s."segment_mean"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14 s
    WHERE s."project_short_name" = 'TCGA-LAML'
      AND s."chromosome" = '15'
),
overlaps AS (
    SELECT
        seg."case_barcode",
        /* amount of each segment that actually falls inside 15q11 */
        LEAST(seg."end_pos", cb.cb_end) - GREATEST(seg."start_pos", cb.cb_start) + 1  AS overlap_len,
        seg."segment_mean"
    FROM segments seg
    CROSS JOIN cytoband cb
    WHERE seg."end_pos"   >= cb.cb_start   -- segment reaches into cytoband
      AND seg."start_pos" <= cb.cb_end     -- segment starts before cytoband ends
),
weighted_avg AS (
    SELECT
        "case_barcode",
        SUM("segment_mean" * overlap_len) / SUM(overlap_len)  AS weighted_avg
    FROM overlaps
    WHERE overlap_len > 0
    GROUP BY "case_barcode"
),
max_val AS (
    SELECT MAX(weighted_avg) AS max_avg FROM weighted_avg
)
SELECT 
    w."case_barcode",
    ROUND(w.weighted_avg, 4) AS weighted_avg_15q11
FROM weighted_avg w
JOIN max_val m
  ON w.weighted_avg = m.max_avg
ORDER BY weighted_avg_15q11 DESC NULLS LAST;