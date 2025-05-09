WITH segment_cytoband AS (
    SELECT 
        s."case_barcode",
        s."chromosome",
        s."start_pos",
        s."end_pos",
        s."copy_number",
        c."cytoband_name"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
        ON s."chromosome" = c."chromosome"
        AND s."start_pos" <= c."hg38_stop"
        AND s."end_pos" >= c."hg38_start"
    WHERE s."project_short_name" = 'TCGA-KIRC'
),
max_copy_number_per_sample_cytoband AS (
    SELECT 
        "case_barcode",
        "chromosome",
        "cytoband_name",
        MAX("copy_number") AS "max_copy_number"
    FROM segment_cytoband
    GROUP BY "case_barcode", "chromosome", "cytoband_name"
),
classified_max_copy_numbers AS (
    SELECT 
        "case_barcode",
        "chromosome",
        "cytoband_name",
        "max_copy_number",
        CASE
            WHEN "max_copy_number" > 3 THEN 'Amplification'
            WHEN "max_copy_number" = 3 THEN 'Gain'
            WHEN "max_copy_number" = 2 THEN 'Normal'
            WHEN "max_copy_number" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_copy_number" = 0 THEN 'Homozygous Deletion'
            ELSE 'Unknown'
        END AS "classification"
    FROM max_copy_number_per_sample_cytoband
),
total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS "total_cases"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
)
SELECT 
    c."chromosome" AS "Chromosome",
    c."cytoband_name" AS "Cytoband",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN c."classification" = 'Amplification' THEN c."case_barcode" END) / tc."total_cases", 4) AS "Amplification",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN c."classification" = 'Gain' THEN c."case_barcode" END) / tc."total_cases", 4) AS "Gain",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN c."classification" = 'Heterozygous Deletion' THEN c."case_barcode" END) / tc."total_cases", 4) AS "Heterozygous Deletion",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN c."classification" = 'Homozygous Deletion' THEN c."case_barcode" END) / tc."total_cases", 4) AS "Homozygous Deletion",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN c."classification" = 'Normal' THEN c."case_barcode" END) / tc."total_cases", 4) AS "Normal"
FROM classified_max_copy_numbers c
CROSS JOIN total_cases tc
GROUP BY c."chromosome", c."cytoband_name", tc."total_cases"
ORDER BY 
    CASE c."chromosome"
        WHEN 'chr1' THEN 1
        WHEN 'chr2' THEN 2
        WHEN 'chr3' THEN 3
        WHEN 'chr4' THEN 4
        WHEN 'chr5' THEN 5
        WHEN 'chr6' THEN 6
        WHEN 'chr7' THEN 7
        WHEN 'chr8' THEN 8
        WHEN 'chr9' THEN 9
        WHEN 'chr10' THEN 10
        WHEN 'chr11' THEN 11
        WHEN 'chr12' THEN 12
        WHEN 'chr13' THEN 13
        WHEN 'chr14' THEN 14
        WHEN 'chr15' THEN 15
        WHEN 'chr16' THEN 16
        WHEN 'chr17' THEN 17
        WHEN 'chr18' THEN 18
        WHEN 'chr19' THEN 19
        WHEN 'chr20' THEN 20
        WHEN 'chr21' THEN 21
        WHEN 'chr22' THEN 22
        WHEN 'chrX' THEN 23
        WHEN 'chrY' THEN 24
        ELSE 25
    END,
    c."cytoband_name";