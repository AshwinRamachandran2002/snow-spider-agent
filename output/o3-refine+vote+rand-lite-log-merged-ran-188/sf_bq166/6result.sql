/*-----------------------------------------------------------
   Copy‑number profile of TCGA‑KIRC samples at cytoband level
-----------------------------------------------------------*/
WITH kirc_segments AS (     -- segment‑level CN data restricted to TCGA‑KIRC
    SELECT
        "case_barcode",
        "chromosome",        -- e.g. 'chr1'
        "start_pos",
        "end_pos",
        "copy_number"
    FROM  TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),

cytobands AS (               -- hg38 cytoband definition
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM  TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
),

/* join every segment with any cytoband it overlaps on the same chromosome */
seg_x_band AS (
    SELECT
        s."case_barcode",
        b."chromosome",
        b."cytoband_name",
        s."copy_number",
        ROW_NUMBER() OVER (                  -- highest copy number per case × band
            PARTITION BY s."case_barcode", b."cytoband_name"
            ORDER BY s."copy_number" DESC
        ) AS rn
    FROM kirc_segments s
    JOIN cytobands   b
      ON  s."chromosome" = b."chromosome"
     AND s."start_pos"  <= b."hg38_stop"
     AND s."end_pos"    >= b."hg38_start"
),

max_cn_per_case_band AS (
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        "copy_number"
    FROM seg_x_band
    WHERE rn = 1
),

classified AS (              -- translate copy numbers into categories
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN "copy_number" > 3 THEN 'Amplification'
            WHEN "copy_number" = 3 THEN 'Gain'
            WHEN "copy_number" = 2 THEN 'Normal'
            WHEN "copy_number" = 1 THEN 'Heterozygous Deletion'
            WHEN "copy_number" = 0 THEN 'Homozygous Deletion'
        END AS subtype
    FROM max_cn_per_case_band
),

total_cases AS (             -- number of distinct TCGA‑KIRC cases
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM   kirc_segments
)

/*------------------- final frequency table -------------------*/
SELECT
    c."chromosome",
    c."cytoband_name",

    ROUND( (COUNT_IF(subtype = 'Amplification')         / t.n_cases)::FLOAT * 100 , 4) AS amplification_pct,
    ROUND( (COUNT_IF(subtype = 'Gain')                  / t.n_cases)::FLOAT * 100 , 4) AS gain_pct,
    ROUND( (COUNT_IF(subtype = 'Homozygous Deletion')   / t.n_cases)::FLOAT * 100 , 4) AS homozygous_deletion_pct,
    ROUND( (COUNT_IF(subtype = 'Heterozygous Deletion') / t.n_cases)::FLOAT * 100 , 4) AS heterozygous_deletion_pct,
    ROUND( (COUNT_IF(subtype = 'Normal')                / t.n_cases)::FLOAT * 100 , 4) AS normal_pct

FROM   classified c
CROSS  JOIN total_cases t
GROUP  BY c."chromosome", c."cytoband_name", t.n_cases
ORDER  BY
    /* numeric chromosomes first, then X, Y, then anything else */
    CASE
        WHEN REGEXP_LIKE(c."chromosome", '^chr[0-9]+$')
             THEN TO_NUMBER(SUBSTR(c."chromosome", 4))
        WHEN c."chromosome" = 'chrX' THEN 23
        WHEN c."chromosome" = 'chrY' THEN 24
        ELSE 25
    END,
    c."cytoband_name";