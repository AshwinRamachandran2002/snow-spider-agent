WITH kirc_cases AS (     -- total distinct TCGA-KIRC cases with allelic CN-segment data
    SELECT DISTINCT "case_barcode"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-KIRC'
),

cytoband_max AS (        -- per case & cytoband, keep the highest observed copy-number
    SELECT
        s."case_barcode",
        c."chromosome",
        c."cytoband_name",
        MAX(s."copy_number") AS "max_copy"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 AS s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38                                   AS c
      ON s."chromosome" = c."chromosome"
     AND s."start_pos"  <= c."hg38_stop"
     AND s."end_pos"    >= c."hg38_start"
    WHERE s."project_short_name" = 'TCGA-KIRC'
    GROUP BY s."case_barcode", c."chromosome", c."cytoband_name"
),

classified AS (          -- translate max_copy into biological CNV sub-types
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN "max_copy" > 3 THEN 'Amplification'
            WHEN "max_copy" = 3 THEN 'Gain'
            WHEN "max_copy" = 2 THEN 'Normal'
            WHEN "max_copy" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_copy" = 0 THEN 'Homozygous Deletion'
            ELSE 'Other'
        END AS "cnv_subtype"
    FROM cytoband_max
),

frequency AS (           -- count how many cases show each subtype per cytoband
    SELECT
        "chromosome",
        "cytoband_name",
        "cnv_subtype",
        COUNT(DISTINCT "case_barcode") AS "num_cases"
    FROM classified
    GROUP BY "chromosome", "cytoband_name", "cnv_subtype"
)

SELECT
    "chromosome",
    "cytoband_name",
    "cnv_subtype",
    ROUND("num_cases" * 100.0 /
          (SELECT COUNT(*) FROM kirc_cases), 4) AS "frequency_pct"
FROM frequency
ORDER BY "chromosome", "cytoband_name";