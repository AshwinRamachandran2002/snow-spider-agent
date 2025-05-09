WITH total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS num_cases
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-KIRC'
),
max_copy_numbers AS (
    SELECT
        s."case_barcode",
        c."chromosome",
        c."cytoband_name",
        MAX(s."copy_number") AS max_copy_number
    FROM
        TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    INNER JOIN
        TCGA_MITELMAN.PROD.CYTOBANDS_HG38 c
    ON
        s."chromosome" = c."chromosome"
        AND s."start_pos" <= c."hg38_stop"
        AND s."end_pos" >= c."hg38_start"
    WHERE
        s."project_short_name" = 'TCGA-KIRC'
    GROUP BY
        s."case_barcode",
        c."chromosome",
        c."cytoband_name"
)
SELECT
    "chromosome" AS Chromosome,
    "cytoband_name" AS Cytoband,
    ROUND((COUNT(DISTINCT CASE WHEN max_copy_number > 3 THEN "case_barcode" ELSE NULL END) * 100.0) / (SELECT num_cases FROM total_cases), 4) AS "Amplification",
    ROUND((COUNT(DISTINCT CASE WHEN max_copy_number = 3 THEN "case_barcode" ELSE NULL END) * 100.0) / (SELECT num_cases FROM total_cases), 4) AS "Gain",
    ROUND((COUNT(DISTINCT CASE WHEN max_copy_number = 1 THEN "case_barcode" ELSE NULL END) * 100.0) / (SELECT num_cases FROM total_cases), 4) AS "Heterozygous Deletion",
    ROUND((COUNT(DISTINCT CASE WHEN max_copy_number = 0 THEN "case_barcode" ELSE NULL END) * 100.0) / (SELECT num_cases FROM total_cases), 4) AS "Homozygous Deletion",
    ROUND((COUNT(DISTINCT CASE WHEN max_copy_number = 2 THEN "case_barcode" ELSE NULL END) * 100.0) / (SELECT num_cases FROM total_cases), 4) AS "Normal"
FROM
    max_copy_numbers
GROUP BY
    "chromosome",
    "cytoband_name"
ORDER BY
    "chromosome",
    "cytoband_name";