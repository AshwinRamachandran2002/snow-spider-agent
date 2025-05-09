WITH kirc_segments AS (   -- segment‑level CN data for TCGA‑KIRC
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),

band_overlap AS (         -- join segments to cytobands (hg38) on genomic overlap
    SELECT
        s."case_barcode",
        b."chromosome",
        b."cytoband_name",
        MAX(s."copy_number")           AS max_copy_number          -- per case / band
    FROM kirc_segments            s
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"  b
      ON  s."chromosome"      = b."chromosome"
      AND s."start_pos"       <= b."hg38_stop"
      AND s."end_pos"         >= b."hg38_start"
    GROUP BY
        s."case_barcode",
        b."chromosome",
        b."cytoband_name"
),

classified AS (           -- categorise max copy number
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        max_copy_number,
        CASE
            WHEN max_copy_number > 3 THEN 'Amplification'
            WHEN max_copy_number = 3 THEN 'Gain'
            WHEN max_copy_number = 2 THEN 'Normal'
            WHEN max_copy_number = 1 THEN 'Heterozygous Deletion'
            WHEN max_copy_number = 0 THEN 'Homozygous Deletion'
            ELSE 'Other'
        END AS subtype
    FROM band_overlap
),

total_cases AS (          -- denominator = distinct cases in TCGA‑KIRC
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM classified
),

freq AS (                 -- frequency of each subtype per cytoband
    SELECT
        c."chromosome",
        c."cytoband_name",
        ROUND(100 * COUNT_IF(c.subtype = 'Amplification')        / t.n_cases , 4) AS amplification_pct,
        ROUND(100 * COUNT_IF(c.subtype = 'Gain')                 / t.n_cases , 4) AS gain_pct,
        ROUND(100 * COUNT_IF(c.subtype = 'Normal')               / t.n_cases , 4) AS normal_pct,
        ROUND(100 * COUNT_IF(c.subtype = 'Heterozygous Deletion')/ t.n_cases , 4) AS heterozygous_deletion_pct,
        ROUND(100 * COUNT_IF(c.subtype = 'Homozygous Deletion')  / t.n_cases , 4) AS homozygous_deletion_pct
    FROM classified c
    CROSS JOIN total_cases t
    GROUP BY
        c."chromosome",
        c."cytoband_name",
        t.n_cases
)

SELECT *
FROM   freq
ORDER BY
       "chromosome",
       "cytoband_name";