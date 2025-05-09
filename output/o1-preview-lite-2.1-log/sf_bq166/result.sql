SELECT 
    c."chromosome" AS "Chromosome",
    c."cytoband_name" AS "Cytoband",
    SUM(CASE WHEN s."copy_number" > 3 THEN 1 ELSE 0 END) AS "Amplifications",
    SUM(CASE WHEN s."copy_number" = 3 THEN 1 ELSE 0 END) AS "Gains",
    SUM(CASE WHEN s."copy_number" = 0 THEN 1 ELSE 0 END) AS "Homozygous_Deletions",
    SUM(CASE WHEN s."copy_number" = 1 THEN 1 ELSE 0 END) AS "Heterozygous_Deletions",
    SUM(CASE WHEN s."copy_number" = 2 THEN 1 ELSE 0 END) AS "Normal_Diploid"
FROM 
    TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
JOIN 
    TCGA_MITELMAN.PROD.CYTOBANDS_HG38 c
ON 
    s."chromosome" = c."chromosome"
    AND s."start_pos" <= c."hg38_stop"
    AND s."end_pos" >= c."hg38_start"
WHERE 
    s."project_short_name" = 'TCGA-KIRC'
GROUP BY 
    c."chromosome", c."cytoband_name"
ORDER BY 
    c."chromosome", c."cytoband_name";