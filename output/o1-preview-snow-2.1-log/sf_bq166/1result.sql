SELECT 
    sub."chromosome" AS "Chromosome", 
    sub."cytoband_name" AS "Cytoband",
    COUNT(CASE WHEN sub."max_cn" > 3 THEN 1 END) AS "Amplifications",
    COUNT(CASE WHEN sub."max_cn" = 3 THEN 1 END) AS "Gains",
    COUNT(CASE WHEN sub."max_cn" = 0 THEN 1 END) AS "Homozygous_Deletions",
    COUNT(CASE WHEN sub."max_cn" = 1 THEN 1 END) AS "Heterozygous_Deletions",
    COUNT(CASE WHEN sub."max_cn" = 2 THEN 1 END) AS "Normal_Copy_States"
FROM (
    SELECT 
        c."chromosome",
        c."cytoband_name",
        s."case_barcode",
        MAX(s."copy_number") AS "max_cn"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
        ON s."chromosome" = c."chromosome"
        AND s."start_pos" <= c."hg38_stop"
        AND s."end_pos" >= c."hg38_start"
    WHERE s."project_short_name" = 'TCGA-KIRC'
    GROUP BY c."chromosome", c."cytoband_name", s."case_barcode"
    ) AS sub
GROUP BY sub."chromosome", sub."cytoband_name"
ORDER BY sub."chromosome", sub."cytoband_name";