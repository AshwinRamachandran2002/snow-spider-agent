/*------------------------------------------------------------
  Case barcodes from the TCGA-LAML study that show the
  highest weighted-average copy number within cytoband 15q11
  on chromosome 15 (hg38 coordinates).
------------------------------------------------------------*/
WITH cytoband_region AS (          -- 15q11 coordinates
    SELECT
        "hg38_start" AS band_start,
        "hg38_stop"  AS band_end
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" LIKE '15q11%'      -- 15q11, 15q11.1, 15q11.2, …
),
cn_segments AS (                   -- CN segments for TCGA-LAML
    SELECT
        "case_barcode",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-LAML'
      AND "chromosome" = 'chr15'
),
overlap_cn AS (                    -- segment ↔ cytoband overlaps
    SELECT
        s."case_barcode",
        GREATEST(s."start_pos", c.band_start) AS ov_start,
        LEAST  (s."end_pos"  , c.band_end)   AS ov_end,
        s."copy_number"
    FROM cn_segments s
    JOIN cytoband_region c
      ON s."end_pos"   >= c.band_start
     AND s."start_pos" <= c.band_end
),
weighted_avg AS (                  -- weighted sums per case
    SELECT
        "case_barcode",
        SUM( (ov_end - ov_start + 1) * "copy_number") AS weighted_sum,
        SUM(  ov_end - ov_start + 1 )                 AS total_len
    FROM overlap_cn
    GROUP BY "case_barcode"
),
avg_per_case AS (                  -- final weighted averages
    SELECT
        "case_barcode",
        weighted_sum / NULLIF(total_len, 0)           AS avg_copy_number
    FROM weighted_avg
)
SELECT
    "case_barcode",
    ROUND(avg_copy_number, 4) AS avg_copy_number
FROM avg_per_case
QUALIFY RANK() OVER (ORDER BY avg_copy_number DESC NULLS LAST) = 1;  -- highest value