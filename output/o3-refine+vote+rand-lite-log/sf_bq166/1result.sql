WITH kirc_segments AS (   -- segment‑level CN data restricted to TCGA‑KIRC
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),

kirc_cases AS (           -- all distinct TCGA‑KIRC cases
    SELECT DISTINCT "case_barcode" FROM kirc_segments
),

total_cases AS (          -- number of TCGA‑KIRC cases (denominator for %)
    SELECT COUNT(*) AS n_cases FROM kirc_cases
),

seg_to_band AS (          -- overlap each segment with cytobands (hg38)
    SELECT
        s."case_barcode",
        b."chromosome",
        b."cytoband_name",
        s."copy_number",
        /* bp overlap length; >0 keeps only intersecting pairs */
        GREATEST(
            0,
            LEAST(s."end_pos",   b."hg38_stop") -
            GREATEST(s."start_pos", b."hg38_start")
        ) AS overlap_bp
    FROM kirc_segments AS s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38" AS b
          ON s."chromosome" = b."chromosome"
    WHERE
        /* keep rows with any positive overlap */
        LEAST(s."end_pos",   b."hg38_stop") >
        GREATEST(s."start_pos", b."hg38_start")
),

max_copy_per_case_band AS (   -- maximum copy number per cytoband & case
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        MAX("copy_number") AS max_copy_number
    FROM seg_to_band
    GROUP BY
        "case_barcode",
        "chromosome",
        "cytoband_name"
),

classified AS (              -- classify copy‑number state
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
        END AS subtype
    FROM max_copy_per_case_band
),

freq_per_band AS (           -- count cases per subtype & cytoband
    SELECT
        "chromosome",
        "cytoband_name",
        COUNT(DISTINCT CASE WHEN subtype = 'Amplification'        THEN "case_barcode" END) AS amp_cnt,
        COUNT(DISTINCT CASE WHEN subtype = 'Gain'                 THEN "case_barcode" END) AS gain_cnt,
        COUNT(DISTINCT CASE WHEN subtype = 'Normal'               THEN "case_barcode" END) AS normal_cnt,
        COUNT(DISTINCT CASE WHEN subtype = 'Heterozygous Deletion' THEN "case_barcode" END) AS hetdel_cnt,
        COUNT(DISTINCT CASE WHEN subtype = 'Homozygous Deletion'   THEN "case_barcode" END) AS homdel_cnt
    FROM classified
    GROUP BY
        "chromosome",
        "cytoband_name"
)

SELECT
    f."chromosome",
    f."cytoband_name",
    ROUND(100.0 * f.amp_cnt    / tc.n_cases, 4) AS "AMPLIFICATION_PCT",
    ROUND(100.0 * f.gain_cnt   / tc.n_cases, 4) AS "GAIN_PCT",
    ROUND(100.0 * f.homdel_cnt / tc.n_cases, 4) AS "HOMOZYGOUS_DEL_PCT",
    ROUND(100.0 * f.hetdel_cnt / tc.n_cases, 4) AS "HETEROZYGOUS_DEL_PCT",
    ROUND(100.0 * f.normal_cnt / tc.n_cases, 4) AS "NORMAL_PCT"
FROM freq_per_band AS f
CROSS JOIN total_cases AS tc
ORDER BY
    f."chromosome",
    f."cytoband_name";