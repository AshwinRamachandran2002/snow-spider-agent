WITH
-- 1)  TCGA‑KIRC segments
kirc_segments AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM
        "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE
        "project_short_name" = 'TCGA-KIRC'
),

-- 2)  join segments with cytobands (keep rows that overlap ≥1 bp)
seg_band_overlap AS (
    SELECT
        ks."case_barcode",
        cb."chromosome",
        cb."cytoband_name",
        ks."copy_number"
    FROM
        kirc_segments            ks
        JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" cb
          ON ks."chromosome" = cb."chromosome"
         AND LEAST( ks."end_pos",   cb."hg38_stop")  -- overlap end
           > GREATEST( ks."start_pos", cb."hg38_start")  -- overlap start
),

-- 3)  per‑case maximum copy number within every cytoband
band_case_max AS (
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        MAX("copy_number") AS max_cn
    FROM seg_band_overlap
    GROUP BY
        "case_barcode",
        "chromosome",
        "cytoband_name"
),

-- 4)  classify each case / cytoband
band_case_class AS (
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN max_cn > 3 THEN 'AMPLIFICATION'
            WHEN max_cn = 3 THEN 'GAIN'
            WHEN max_cn = 2 THEN 'NORMAL'
            WHEN max_cn = 1 THEN 'HETERO_DELETION'
            WHEN max_cn = 0 THEN 'HOMO_DELETION'
            ELSE 'OTHER'
        END AS class_label
    FROM band_case_max
),

-- 5)  count cases per class & cytoband
band_counts AS (
    SELECT
        "chromosome",
        "cytoband_name",
        SUM( CASE WHEN class_label = 'AMPLIFICATION'      THEN 1 ELSE 0 END) AS amp,
        SUM( CASE WHEN class_label = 'GAIN'               THEN 1 ELSE 0 END) AS gain,
        SUM( CASE WHEN class_label = 'NORMAL'             THEN 1 ELSE 0 END) AS normal,
        SUM( CASE WHEN class_label = 'HETERO_DELETION'    THEN 1 ELSE 0 END) AS hetero_del,
        SUM( CASE WHEN class_label = 'HOMO_DELETION'      THEN 1 ELSE 0 END) AS homo_del
    FROM band_case_class
    GROUP BY
        "chromosome",
        "cytoband_name"
),

-- 6)  total number of distinct TCGA‑KIRC cases
total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
)

-- 7)  final percentages
SELECT
    bc."chromosome",
    bc."cytoband_name",
    ROUND(100.0 * bc.amp       / tc.n_cases, 4) AS amplification_pct,
    ROUND(100.0 * bc.gain      / tc.n_cases, 4) AS gain_pct,
    ROUND(100.0 * bc.normal    / tc.n_cases, 4) AS normal_pct,
    ROUND(100.0 * bc.hetero_del/ tc.n_cases, 4) AS heterozygous_deletion_pct,
    ROUND(100.0 * bc.homo_del  / tc.n_cases, 4) AS homozygous_deletion_pct
FROM
    band_counts bc
    CROSS JOIN total_cases tc
ORDER BY
    bc."chromosome",
    bc."cytoband_name";