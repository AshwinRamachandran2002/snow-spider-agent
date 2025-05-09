WITH cytoband AS (
    /* Coordinates for cytoband 15q11 (hg38) on chr15 */
    SELECT "hg38_start" AS band_start,
           "hg38_stop"  AS band_stop
    FROM   "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
    WHERE  "chromosome" = 'chr15'
      AND  "cytoband_name" = '15q11'
),
case_level AS (
    /* Weighted‑average copy number per TCGA‑LAML case inside 15q11 */
    SELECT
        seg."case_barcode",
        SUM(seg."segment_mean" * seg."num_probes")
        / NULLIF(SUM(seg."num_probes"), 0)  AS weighted_avg_copy_number_15q11
    FROM   "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02" seg,
           cytoband cb
    WHERE  seg."project_short_name" = 'TCGA-LAML'
      AND  seg."chromosome"        = '15'
      AND  seg."end_pos"           >= cb.band_start   /* overlap with 15q11 */
      AND  seg."start_pos"         <= cb.band_stop
    GROUP  BY seg."case_barcode"
),
max_val AS (
    SELECT MAX(weighted_avg_copy_number_15q11) AS max_cn
    FROM   case_level
)
SELECT
    cl."case_barcode",
    ROUND(cl.weighted_avg_copy_number_15q11, 4) AS weighted_avg_copy_number_15q11
FROM   case_level cl
JOIN   max_val mv
  ON   cl.weighted_avg_copy_number_15q11 = mv.max_cn
ORDER BY cl."case_barcode";