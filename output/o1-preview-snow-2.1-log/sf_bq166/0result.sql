SELECT
    c."chromosome" AS "Chromosome",
    c."cytoband_name" AS "Cytoband",
    SUM(CASE WHEN s."segment_mean" >= 0.58 THEN 1 ELSE 0 END) AS "Amplifications",
    SUM(CASE WHEN s."segment_mean" BETWEEN 0.25 AND 0.58 THEN 1 ELSE 0 END) AS "Gains",
    SUM(CASE WHEN s."segment_mean" < -1 THEN 1 ELSE 0 END) AS "Homozygous_Deletions",
    SUM(CASE WHEN s."segment_mean" BETWEEN -1 AND -0.25 THEN 1 ELSE 0 END) AS "Heterozygous_Deletions",
    SUM(CASE WHEN s."segment_mean" BETWEEN -0.25 AND 0.25 THEN 1 ELSE 0 END) AS "Normal_Copy_States"
FROM
    TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14" s
JOIN
    TCGA_MITELMAN.PROD."CYTOBANDS_HG38" c
    ON c."chromosome" = 'chr' || s."chromosome"
    AND s."end_pos" >= c."hg38_start"
    AND s."start_pos" <= c."hg38_stop"
WHERE
    s."project_short_name" = 'TCGA-KIRC'
GROUP BY
    c."chromosome",
    c."cytoband_name"
ORDER BY
    c."chromosome",
    c."cytoband_name";