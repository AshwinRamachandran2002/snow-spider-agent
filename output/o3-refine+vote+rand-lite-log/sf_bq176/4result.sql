/* 1.  Locate genomic coordinates for cytoband 15q11 (hg38)               */
/* 2.  Intersect TCGA‑LAML copy‑number segments with those coordinates    */
/* 3.  Compute the length‑weighted average segment_mean per case          */
/* 4.  Return the case barcode(s) whose weighted average is the highest   */

WITH band AS (
    SELECT
        MIN("hg38_start") AS band_start,
        MAX("hg38_stop")  AS band_stop
    FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" ILIKE '15q11%'          -- all sub‑bands of 15q11
),
segments AS (
    SELECT
        s."case_barcode",
        s."start_pos",
        s."end_pos",
        s."segment_mean",
        /* length of overlap between segment and cytoband */
        LEAST(s."end_pos",  b.band_stop)
      - GREATEST(s."start_pos", b.band_start) + 1        AS overlap_len
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02"  s
    CROSS JOIN band b
    WHERE s."project_short_name" = 'TCGA-LAML'
      AND s."chromosome" = '15'
      AND s."end_pos"   >= b.band_start      -- segment overlaps band
      AND s."start_pos" <= b.band_stop
),
agg AS (
    SELECT
        "case_barcode",
        SUM("segment_mean" * overlap_len) / SUM(overlap_len)  AS weighted_avg_cn
    FROM segments
    WHERE overlap_len > 0
    GROUP BY "case_barcode"
),
max_cn AS (
    SELECT MAX(weighted_avg_cn) AS max_val FROM agg
)
SELECT
    a."case_barcode",
    ROUND(a.weighted_avg_cn, 4) AS "weighted_avg_copy_number"
FROM agg a
JOIN max_cn m ON a.weighted_avg_cn = m.max_val
ORDER BY a."case_barcode";