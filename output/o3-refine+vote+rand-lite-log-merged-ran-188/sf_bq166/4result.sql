WITH total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS total_cases
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),
segment_filtered AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),
band_overlap AS (
    SELECT
        sf."case_barcode",
        cb."chromosome",
        cb."cytoband_name",
        sf."copy_number"
    FROM segment_filtered sf
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" cb
      ON sf."chromosome" = cb."chromosome"
     AND sf."start_pos" <= cb."hg38_stop"
     AND sf."end_pos"   >= cb."hg38_start"
),
max_copy_per_band AS (
    SELECT
        "chromosome",
        "cytoband_name",
        "case_barcode",
        MAX("copy_number") AS max_copy_number
    FROM band_overlap
    GROUP BY
        "chromosome",
        "cytoband_name",
        "case_barcode"
),
classified AS (
    SELECT
        "chromosome",
        "cytoband_name",
        CASE
            WHEN max_copy_number > 3 THEN 'Amplification'
            WHEN max_copy_number = 3 THEN 'Gain'
            WHEN max_copy_number = 2 THEN 'Normal'
            WHEN max_copy_number = 1 THEN 'Heterozygous Deletion'
            WHEN max_copy_number = 0 THEN 'Homozygous Deletion'
            ELSE 'Other'
        END AS subtype,
        "case_barcode"
    FROM max_copy_per_band
),
freq AS (
    SELECT
        "chromosome",
        "cytoband_name",
        subtype,
        COUNT(DISTINCT "case_barcode") AS case_count
    FROM classified
    GROUP BY
        "chromosome",
        "cytoband_name",
        subtype
)
SELECT
    f."chromosome",
    f."cytoband_name",
    f.subtype,
    ROUND(f.case_count * 100.0 / tc.total_cases, 4) AS percentage_of_cases
FROM freq f
CROSS JOIN total_cases tc
ORDER BY
    f."chromosome",
    f."cytoband_name",
    f.subtype;