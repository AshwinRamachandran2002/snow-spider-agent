/*---------------------------------------------------------------------------
   Copy‑number aberration frequencies per cytoband – TCGA‑KIRC
---------------------------------------------------------------------------*/
WITH kirc_segments AS (              -- segment–level CN data restricted to TCGA‑KIRC
    SELECT
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number",
        "case_barcode"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),
total_cases AS (                      -- total number of independent cases
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM kirc_segments
),
per_case_band AS (                    -- max copy‑number per case & cytoband
    SELECT
        b."chromosome",
        b."cytoband_name",
        s."case_barcode",
        MAX(s."copy_number") AS max_cn
    FROM kirc_segments        s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38"  b
      ON s."chromosome"       = b."chromosome"
     AND s."start_pos"        <= b."hg38_stop"
     AND s."end_pos"          >= b."hg38_start"
    GROUP BY
        b."chromosome",
        b."cytoband_name",
        s."case_barcode"
),
classified AS (                       -- classify each case‑band combination
    SELECT
        "chromosome",
        "cytoband_name",
        "case_barcode",
        CASE
            WHEN max_cn > 3  THEN 'Amplification'
            WHEN max_cn = 3  THEN 'Gain'
            WHEN max_cn = 2  THEN 'Normal'
            WHEN max_cn = 1  THEN 'Heterozygous Deletion'
            WHEN max_cn = 0  THEN 'Homozygous Deletion'
        END AS subtype
    FROM per_case_band
)
SELECT
    c."chromosome",
    c."cytoband_name",
    ROUND(100.0 * SUM( CASE WHEN subtype = 'Amplification'        THEN 1 ELSE 0 END ) / tc.n_cases, 4) AS amplification_pct,
    ROUND(100.0 * SUM( CASE WHEN subtype = 'Gain'                 THEN 1 ELSE 0 END ) / tc.n_cases, 4) AS gain_pct,
    ROUND(100.0 * SUM( CASE WHEN subtype = 'Homozygous Deletion'  THEN 1 ELSE 0 END ) / tc.n_cases, 4) AS homdel_pct,
    ROUND(100.0 * SUM( CASE WHEN subtype = 'Heterozygous Deletion'THEN 1 ELSE 0 END ) / tc.n_cases, 4) AS hetdel_pct,
    ROUND(100.0 * SUM( CASE WHEN subtype = 'Normal'               THEN 1 ELSE 0 END ) / tc.n_cases, 4) AS normal_pct
FROM  classified  c
CROSS JOIN total_cases tc            -- supplies denominator for percentages
GROUP BY
    c."chromosome",
    c."cytoband_name",
    tc.n_cases
ORDER BY
    c."chromosome",
    c."cytoband_name";