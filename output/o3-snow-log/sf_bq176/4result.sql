WITH band AS (   -- 15q11 cytoband limits on chr15 (hg38)
    SELECT 
        "hg38_start",
        "hg38_stop",
        "chromosome"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" LIKE '15q11%'          -- 15q11, 15q11.1, 15q11.2 …
), 
overlaps AS (   -- CN-segment portions that overlap 15q11 for TCGA-LAML
    SELECT
        s."case_barcode",
        s."copy_number",
        GREATEST(s."start_pos", b."hg38_start") AS overlap_start,
        LEAST(s."end_pos",   b."hg38_stop")     AS overlap_end
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    JOIN band b
      ON s."chromosome"   = b."chromosome"
     AND s."end_pos"      >= b."hg38_start"
     AND s."start_pos"    <= b."hg38_stop"
    WHERE s."project_short_name" = 'TCGA-LAML'
), 
weighted AS (   -- length-weighted sums per case
    SELECT
        "case_barcode",
        SUM("copy_number" * (overlap_end - overlap_start + 1)) AS weighted_sum,
        SUM(overlap_end - overlap_start + 1)                  AS total_len
    FROM overlaps
    GROUP BY "case_barcode"
), 
averages AS (   -- weighted average copy number per case
    SELECT
        "case_barcode",
        weighted_sum / total_len AS weighted_avg
    FROM weighted
), 
max_val AS (    -- highest average among all cases
    SELECT MAX(weighted_avg) AS max_avg
    FROM averages
)
SELECT
    a."case_barcode",
    a.weighted_avg
FROM averages a
JOIN max_val m
  ON a.weighted_avg = m.max_avg          -- keep only highest-scoring case(s)
ORDER BY a.weighted_avg DESC NULLS LAST;