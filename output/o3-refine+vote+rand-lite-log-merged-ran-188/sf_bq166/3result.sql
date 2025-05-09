WITH
-- 1. Segment‑level data restricted to TCGA‑KIRC
seg AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),

-- 2. Cytoband definitions
bands AS (
    SELECT
        "chromosome",
        "hg38_start",
        "hg38_stop",
        "cytoband_name"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
),

-- 3. Join segments to bands whenever they overlap
seg_band AS (
    SELECT
        s."case_barcode",
        s."chromosome",
        b."cytoband_name",
        s."copy_number"
    FROM seg s
    JOIN bands b
      ON  s."chromosome" = b."chromosome"
      AND s."start_pos" <= b."hg38_stop"
      AND s."end_pos"   >= b."hg38_start"
),

-- 4. For every case‑band pair get the maximal copy number
max_cn AS (
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        MAX("copy_number") AS max_cn
    FROM seg_band
    GROUP BY
        "case_barcode",
        "chromosome",
        "cytoband_name"
),

-- 5. Classify the maximal copy number
classified AS (
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        max_cn,
        CASE
            WHEN max_cn > 3 THEN 'Amplification'
            WHEN max_cn = 3 THEN 'Gain'
            WHEN max_cn = 2 THEN 'Normal'
            WHEN max_cn = 1 THEN 'Heterozygous Deletion'
            ELSE                'Homozygous Deletion'   -- max_cn = 0
        END AS SUBTYPE
    FROM max_cn
),

-- 6. Total number of distinct TCGA‑KIRC cases
tot AS (
    SELECT COUNT(DISTINCT "case_barcode") AS total_cases
    FROM seg
)

-- 7. Frequency of each subtype per cytoband
SELECT
    c."chromosome",
    c."cytoband_name",
    c.SUBTYPE,
    ROUND( COUNT(DISTINCT c."case_barcode") * 100.0 / t.total_cases , 4) AS frequency_percent
FROM classified c
CROSS JOIN tot t
GROUP BY
    c."chromosome",
    c."cytoband_name",
    c.SUBTYPE,
    t.total_cases
ORDER BY
    TRY_TO_NUMBER(REPLACE(c."chromosome",'chr','')) NULLS LAST,
    c."cytoband_name";