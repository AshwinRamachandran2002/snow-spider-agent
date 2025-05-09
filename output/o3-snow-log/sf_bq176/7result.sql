WITH band AS (   -- genomic range of cytoband 15q11 in hg38
    SELECT 
        "hg38_start"  AS band_start,
        "hg38_stop"   AS band_stop
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" LIKE '15q11%'        -- 15q11, 15q11.1, 15q11.2, etc.
), 

segments AS (    -- TCGA-LAML copy-number segments on chr15
    SELECT
        "case_barcode",
        "start_pos"  AS seg_start,
        "end_pos"    AS seg_end,
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-LAML'
      AND "chromosome" = 'chr15'
),

overlaps AS (    -- length of each segment that overlaps any part of 15q11
    SELECT
        s."case_barcode",
        s."copy_number",
        GREATEST(
            0,
            LEAST(s.seg_end , b.band_stop) 
          - GREATEST(s.seg_start, b.band_start) + 1
        ) AS overlap_len
    FROM segments s
    JOIN band b
      ON s.seg_end   >= b.band_start
     AND s.seg_start <= b.band_stop
),

weighted AS (    -- weighted-average copy number per case
    SELECT
        "case_barcode",
        SUM(overlap_len * "copy_number") 
        / NULLIF(SUM(overlap_len),0)   AS weighted_avg_cn
    FROM overlaps
    WHERE overlap_len > 0
    GROUP BY "case_barcode"
),

max_cn AS (      -- highest weighted-average value
    SELECT MAX(weighted_avg_cn) AS max_cn
    FROM weighted
)

SELECT 
    w."case_barcode",
    w.weighted_avg_cn
FROM weighted w
JOIN max_cn m
  ON w.weighted_avg_cn = m.max_cn
ORDER BY w."case_barcode";