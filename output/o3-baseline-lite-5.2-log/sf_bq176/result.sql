WITH cytoband AS (   -- coordinates of cytoband 15q11 on chr15 (hg38)
    SELECT
        MIN("hg38_start") AS band_start ,
        MAX("hg38_stop")  AS band_end
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" ILIKE '15q11%'        -- 15q11, 15q11.1, 15q11.2 …
),
segments AS (        -- copy‑number segments from TCGA‑LAML on chr15
    SELECT
        s."case_barcode",
        s."start_pos",
        s."end_pos",
        s."copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23  s
    WHERE s."project_short_name" = 'TCGA-LAML'
      AND s."chromosome"        = 'chr15'
      AND s."copy_number"       IS NOT NULL
),
overlap AS (         -- segment lengths that overlap 15q11
    SELECT
        seg."case_barcode",
        GREATEST(seg."start_pos",  cb.band_start)        AS ov_start ,
        LEAST  (seg."end_pos",    cb.band_end)          AS ov_end   ,
        seg."copy_number"
    FROM segments seg
    CROSS JOIN cytoband cb
    WHERE seg."end_pos"   >= cb.band_start              -- has overlap
      AND seg."start_pos" <= cb.band_end
),
weighted AS (        -- weighted‑average copy number per case
    SELECT
        "case_barcode",
        SUM("copy_number" * (ov_end - ov_start + 1)) / 
        SUM(ov_end - ov_start + 1)                      AS weighted_avg_copy_number
    FROM overlap
    GROUP BY "case_barcode"
)
SELECT
    "case_barcode",
    weighted_avg_copy_number
FROM weighted
ORDER BY weighted_avg_copy_number DESC NULLS LAST
LIMIT 10;          -- highest‑scoring TCGA‑LAML cases