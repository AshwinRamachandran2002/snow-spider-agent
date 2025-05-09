WITH
kirc_seg AS (  -- KIRC segments
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),
bands AS (      -- cytoband definitions
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
),
overlaps AS (   -- segment × cytoband overlaps
    SELECT
        s."case_barcode",
        b."chromosome",
        b."cytoband_name",
        s."copy_number",
        GREATEST(s."start_pos", b."hg38_start") AS ov_start,
        LEAST   (s."end_pos" , b."hg38_stop" ) AS ov_end
    FROM kirc_seg s
    JOIN bands   b
      ON s."chromosome" = b."chromosome"
     AND LEAST(s."end_pos",  b."hg38_stop")
       > GREATEST(s."start_pos", b."hg38_start")          -- positive overlap
),
cytoband_max AS (   -- max copy number per case × cytoband
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        MAX("copy_number") AS max_copy_number
    FROM overlaps
    GROUP BY
        "case_barcode",
        "chromosome",
        "cytoband_name"
),
classified AS (     -- classify copy‑number state
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN max_copy_number > 3 THEN 'Amplification'
            WHEN max_copy_number = 3 THEN 'Gain'
            WHEN max_copy_number = 2 THEN 'Normal'
            WHEN max_copy_number = 1 THEN 'Heterozygous Deletion'
            WHEN max_copy_number = 0 THEN 'Homozygous Deletion'
            ELSE 'Other'
        END AS cnv_class
    FROM cytoband_max
),
tot_cases AS (      -- total distinct KIRC cases
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM kirc_seg
)

SELECT
    c."chromosome",
    c."cytoband_name",
    c.cnv_class                       AS "CNV_SUBTYPE",
    ROUND(
        100.0 * COUNT(DISTINCT c."case_barcode") / t.n_cases,
        4
    )                                 AS "FREQUENCY_PERCENT"
FROM classified c
CROSS JOIN tot_cases t
GROUP BY
    c."chromosome",
    c."cytoband_name",
    c.cnv_class,
    t.n_cases
ORDER BY
    c."chromosome",
    c."cytoband_name",
    c.cnv_class;