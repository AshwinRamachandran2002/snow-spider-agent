WITH total_cases AS (
    -- total distinct TCGA-KIRC cases represented in the allelic CN-segment table
    SELECT COUNT(DISTINCT "case_barcode") AS "total_cases"
    FROM   TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE  "project_short_name" = 'TCGA-KIRC'
),
per_case_max AS (
    -- for every case × cytoband, keep the maximum observed copy-number
    SELECT
        s."case_barcode",
        c."chromosome",
        c."cytoband_name",
        MAX(s."copy_number") AS "max_cn"
    FROM   TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    JOIN   TCGA_MITELMAN.PROD.CYTOBANDS_HG38                             c
           ON  s."chromosome" = c."chromosome"
           AND s."start_pos"  <= c."hg38_stop"
           AND s."end_pos"    >= c."hg38_start"
    WHERE  s."project_short_name" = 'TCGA-KIRC'
    GROUP BY
        s."case_barcode",
        c."chromosome",
        c."cytoband_name"
),
per_case_class AS (
    -- translate the max copy number into CNV classes
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN "max_cn" > 3 THEN 'Amplification'
            WHEN "max_cn" = 3 THEN 'Gain'
            WHEN "max_cn" = 2 THEN 'Normal'
            WHEN "max_cn" = 1 THEN 'Het_Del'
            WHEN "max_cn" = 0 THEN 'Homo_Del'
        END AS "cnv_class"
    FROM   per_case_max
),
summary_counts AS (
    -- count how many distinct cases fall into each cytoband × class
    SELECT
        "chromosome",
        "cytoband_name",
        "cnv_class",
        COUNT(DISTINCT "case_barcode") AS "n_cases"
    FROM   per_case_class
    GROUP BY
        "chromosome",
        "cytoband_name",
        "cnv_class"
)
-- convert counts to percentages of the total case-count
SELECT
    s."chromosome",
    s."cytoband_name",
    s."cnv_class",
    ROUND(100.0 * s."n_cases" / t."total_cases", 2) AS "pct_cases"
FROM   summary_counts s
CROSS  JOIN total_cases t
ORDER BY
    s."chromosome",
    s."cytoband_name",
    s."cnv_class";