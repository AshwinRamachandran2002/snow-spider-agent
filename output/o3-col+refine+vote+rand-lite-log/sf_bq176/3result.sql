/* Identify the TCGA-LAML case barcode(s) with the highest
   weighted-average copy-number (segment_mean) in cytoband 15q11. */
WITH band AS (   -- genomic limits of cytoband 15q11 on chr15 (hg38)
    SELECT 
        "hg38_start" AS band_start,
        "hg38_stop"  AS band_stop
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" ILIKE '15q11%'          -- 15q11 / 15q11.x
), segments AS ( -- segments that overlap the 15q11 interval
    SELECT
        s."case_barcode",
        s."segment_mean",
        LEAST(s."end_pos",  b.band_stop) 
          - GREATEST(s."start_pos", b.band_start) + 1 AS overlap_len
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14 s
    JOIN band b ON 1=1
    WHERE s."project_short_name" = 'TCGA-LAML'
      AND s."chromosome"        = '15'
      AND LEAST(s."end_pos",  b.band_stop) 
        > GREATEST(s."start_pos", b.band_start)   -- require overlap
), agg AS (      -- weighted-average CN per case
    SELECT
        "case_barcode",
        SUM("segment_mean" * overlap_len) 
        / NULLIF(SUM(overlap_len),0)  AS weighted_avg_cn
    FROM segments
    GROUP BY "case_barcode"
), ranked AS (   -- rank to find the highest value(s)
    SELECT
        "case_barcode",
        weighted_avg_cn,
        RANK() OVER (ORDER BY weighted_avg_cn DESC NULLS LAST) AS rk
    FROM agg
)
SELECT 
    "case_barcode",
    ROUND(weighted_avg_cn, 4) AS weighted_avg_cn
FROM ranked
WHERE rk = 1                       -- highest weighted-average CN
ORDER BY weighted_avg_cn DESC NULLS LAST;