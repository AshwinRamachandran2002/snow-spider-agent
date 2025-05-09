/* -----------------------------------------------------------
   Identify TCGA-LAML cases with the highest length-weighted
   average copy number in cytoband 15q11 (chr15, hg38 build)
   ----------------------------------------------------------- */
WITH band AS (  -- hg38 genomic span(s) of cytoband 15q11
    SELECT
        "hg38_start" AS band_start ,
        "hg38_stop"  AS band_stop
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" ILIKE '15q11%'          -- 15q11, 15q11.1, 15q11.2 …
),

segments AS (   -- CN segments for the TCGA-LAML study on chr15 (hg38)
    SELECT
        "case_barcode",
        "start_pos"  AS seg_start ,
        "end_pos"    AS seg_end ,
        "segment_mean"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14
    WHERE "project_short_name" = 'TCGA-LAML'
      AND "chromosome" = '15'
),

overlaps AS (   -- overlap of segments with the cytoband region(s)
    SELECT
        s."case_barcode",
        LEAST(s.seg_end , b.band_stop ) - GREATEST(s.seg_start , b.band_start) + 1 AS overlap_len ,
        2 * POWER(2, s."segment_mean")                                               AS cn_value  -- absolute CN
    FROM segments s
    JOIN band b
      ON s.seg_start <= b.band_stop
     AND s.seg_end   >= b.band_start            -- ensure genomic overlap
),

agg AS (        -- length-weighted average CN per case
    SELECT
        "case_barcode",
        SUM(overlap_len * cn_value) / SUM(overlap_len) AS weighted_avg_cn
    FROM overlaps
    WHERE overlap_len > 0
    GROUP BY "case_barcode"
),

max_val AS (    -- highest weighted average among all cases
    SELECT MAX(weighted_avg_cn) AS max_cn
    FROM   agg
)

SELECT
    a."case_barcode",
    ROUND(a.weighted_avg_cn, 4) AS weighted_avg_copy_number
FROM agg      a
JOIN max_val  m
  ON a.weighted_avg_cn = m.max_cn             -- retain only the highest value(s)
ORDER BY weighted_avg_copy_number DESC NULLS LAST;