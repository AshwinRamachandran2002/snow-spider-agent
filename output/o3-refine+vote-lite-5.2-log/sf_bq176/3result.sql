WITH cytoband AS (   -- 15q11 region (hg38 coordinates)
    SELECT  "chromosome",
            "hg38_start" AS cb_start,
            "hg38_stop"  AS cb_end
    FROM    TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE   "chromosome" = 'chr15'
      AND   "cytoband_name" LIKE '15q11%'
),
segments AS (        -- copy‑number segments for TCGA‑LAML on chr15
    SELECT  "case_barcode",
            "start_pos",
            "end_pos",
            "segment_mean"
    FROM    TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02
    WHERE   "project_short_name" = 'TCGA-LAML'
      AND   "chromosome" = '15'
),
overlap AS (         -- intersect segments with the cytoband
    SELECT  s."case_barcode" AS "CASE_BARCODE",
            GREATEST(s."start_pos", c.cb_start) AS ov_start,
            LEAST(s."end_pos",    c.cb_end)     AS ov_end,
            s."segment_mean"
    FROM    segments s
    JOIN    cytoband c
          ON s."end_pos"   >= c.cb_start
         AND s."start_pos" <= c.cb_end
),
weighted AS (        -- length‑weighted average per case
    SELECT  "CASE_BARCODE",
            SUM( (ov_end - ov_start + 1) * "segment_mean" ) AS w_sum,
            SUM(  ov_end - ov_start + 1 )                   AS w_len
    FROM    overlap
    GROUP BY "CASE_BARCODE"
),
scores AS (
    SELECT  "CASE_BARCODE",
            w_sum / NULLIF(w_len,0) AS weighted_avg_cn
    FROM    weighted
)
SELECT  "CASE_BARCODE",
        weighted_avg_cn
FROM    scores
QUALIFY  weighted_avg_cn = MAX(weighted_avg_cn) OVER ()   -- keep highest
ORDER BY "CASE_BARCODE";