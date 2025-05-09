/*  Cytoband‑level CNV subtype frequencies (% of TCGA‑KIRC cases)  */
WITH total_cases AS (          -- total number of distinct KIRC cases
    SELECT COUNT(DISTINCT "case_barcode") AS total_n
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),

band_max AS (                  -- maximum copy‑number per case × cytoband
    SELECT
        s."case_barcode",
        b."chromosome",
        b."cytoband_name",
        MAX(s."copy_number") AS max_cn
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"  s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                                       b
      ON s."chromosome" = b."chromosome"
    WHERE s."project_short_name" = 'TCGA-KIRC'
      AND LEAST(s."end_pos", b."hg38_stop") > GREATEST(s."start_pos", b."hg38_start")
    GROUP BY s."case_barcode", b."chromosome", b."cytoband_name"
),

classed AS (                   -- classify the maximum copy numbers
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN max_cn > 3 THEN 'Amplification'
            WHEN max_cn = 3 THEN 'Gain'
            WHEN max_cn = 1 THEN 'Heterozygous Deletion'
            WHEN max_cn = 0 THEN 'Homozygous Deletion'
            ELSE 'Normal'                 -- (=2)
        END AS cnv_class
    FROM band_max
),

cases_per_band AS (            -- counts of cases in each CNV class per cytoband
    SELECT
        "chromosome",
        "cytoband_name",
        COUNT(DISTINCT CASE WHEN cnv_class = 'Amplification'         THEN "case_barcode" END) AS amp_n,
        COUNT(DISTINCT CASE WHEN cnv_class = 'Gain'                  THEN "case_barcode" END) AS gain_n,
        COUNT(DISTINCT CASE WHEN cnv_class = 'Heterozygous Deletion' THEN "case_barcode" END) AS hetdel_n,
        COUNT(DISTINCT CASE WHEN cnv_class = 'Homozygous Deletion'   THEN "case_barcode" END) AS homdel_n,
        COUNT(DISTINCT CASE WHEN cnv_class = 'Normal'                THEN "case_barcode" END) AS normal_n
    FROM classed
    GROUP BY "chromosome", "cytoband_name"
)

SELECT
    c."chromosome"                                                AS chromosome,
    c."cytoband_name"                                             AS cytoband,
    ROUND(100.0 * c.amp_n    / t.total_n, 4)                      AS amplification_pct,
    ROUND(100.0 * c.gain_n   / t.total_n, 4)                      AS gain_pct,
    ROUND(100.0 * c.hetdel_n / t.total_n, 4)                      AS heterozygous_deletion_pct,
    ROUND(100.0 * c.homdel_n / t.total_n, 4)                      AS homozygous_deletion_pct,
    ROUND(100.0 * c.normal_n / t.total_n, 4)                      AS normal_pct
FROM   cases_per_band  c
CROSS  JOIN total_cases t
ORDER  BY c."chromosome", c."cytoband_name";