WITH cytoband AS (
    SELECT 
        "hg38_start" AS cb_start,
        "hg38_stop"  AS cb_stop
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" = '15q11'
),

segments AS (
    SELECT 
        s."case_barcode",
        s."start_pos",
        s."end_pos",
        s."segment_mean",
        c.cb_start,
        c.cb_stop
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02"  s
    JOIN cytoband c ON 1 = 1
    WHERE s."project_short_name" = 'TCGA-LAML'
      AND s."chromosome" = '15'
      AND LEAST(s."end_pos", c.cb_stop) > GREATEST(s."start_pos", c.cb_start)   -- ensures overlap
),

overlaps AS (
    SELECT
        "case_barcode",
        (LEAST("end_pos", cb_stop) - GREATEST("start_pos", cb_start) + 1)     AS overlap_len,
        "segment_mean"
    FROM segments
),

weighted AS (
    SELECT
        "case_barcode",
        SUM("segment_mean" * overlap_len) / SUM(overlap_len)  AS weighted_avg_copy_number
    FROM overlaps
    GROUP BY "case_barcode"
)

SELECT
    "case_barcode",
    weighted_avg_copy_number
FROM weighted
QUALIFY weighted_avg_copy_number = MAX(weighted_avg_copy_number) OVER ()
ORDER BY weighted_avg_copy_number DESC NULLS LAST;