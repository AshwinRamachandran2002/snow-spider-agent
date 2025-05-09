WITH total_cases AS (
    SELECT COUNT(DISTINCT s."case_barcode") AS total_cases
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    WHERE s."project_short_name" = 'TCGA-KIRC'
),
max_copy_numbers AS (
    SELECT
        s."case_barcode",
        s."chromosome",
        c."cytoband_name",
        MAX(s."copy_number") AS max_copy_number
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
        ON s."chromosome" = c."chromosome"
        AND s."start_pos" <= c."hg38_stop"
        AND s."end_pos" >= c."hg38_start"
    WHERE s."project_short_name" = 'TCGA-KIRC'
    GROUP BY s."case_barcode", s."chromosome", c."cytoband_name"
),
classified_max_copy_numbers AS (
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
        END AS classification
    FROM max_copy_numbers
),
counts_per_cytoband AS (
    SELECT
        "chromosome",
        "cytoband_name",
        COUNT(DISTINCT CASE WHEN classification = 'Amplification' THEN "case_barcode" END) AS amplification_cases,
        COUNT(DISTINCT CASE WHEN classification = 'Gain' THEN "case_barcode" END) AS gain_cases,
        COUNT(DISTINCT CASE WHEN classification = 'Heterozygous Deletion' THEN "case_barcode" END) AS heterozygous_deletion_cases,
        COUNT(DISTINCT CASE WHEN classification = 'Homozygous Deletion' THEN "case_barcode" END) AS homozygous_deletion_cases,
        COUNT(DISTINCT CASE WHEN classification = 'Normal' THEN "case_barcode" END) AS normal_cases
    FROM classified_max_copy_numbers
    GROUP BY "chromosome", "cytoband_name"
)
SELECT
    cp."chromosome" AS "Chromosome",
    cp."cytoband_name" AS "Cytoband",
    ROUND((100.0 * cp.amplification_cases / tc.total_cases), 4) AS "Amplification",
    ROUND((100.0 * cp.gain_cases / tc.total_cases), 4) AS "Gain",
    ROUND((100.0 * cp.heterozygous_deletion_cases / tc.total_cases), 4) AS "Heterozygous Deletion",
    ROUND((100.0 * cp.homozygous_deletion_cases / tc.total_cases), 4) AS "Homozygous Deletion",
    ROUND((100.0 * cp.normal_cases / tc.total_cases), 4) AS "Normal"
FROM counts_per_cytoband cp
CROSS JOIN total_cases tc
ORDER BY cp."chromosome", cp."cytoband_name";