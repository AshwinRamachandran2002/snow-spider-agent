WITH per_case AS (  -- 1.  Max copy-number per cytoband for every KIRC case
    SELECT
        s."case_barcode",
        c."chromosome",
        c."cytoband_name",
        MAX(s."copy_number") AS "max_cn"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 AS s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38                                   AS c
      ON s."chromosome" = c."chromosome"
     AND s."start_pos"  <= c."hg38_stop"
     AND s."end_pos"    >= c."hg38_start"
    WHERE s."project_short_name" = 'TCGA-KIRC'
    GROUP BY s."case_barcode", c."chromosome", c."cytoband_name"
),
labeled AS (        -- 2.  Translate max CN values into CNV sub-types
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        "max_cn",
        CASE
            WHEN "max_cn" > 3 THEN 'Amplification'
            WHEN "max_cn" = 3 THEN 'Gain'
            WHEN "max_cn" = 2 THEN 'Normal'
            WHEN "max_cn" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_cn" = 0 THEN 'Homozygous Deletion'
        END AS "cnv_class"
    FROM per_case
),
totals AS (         -- 3.  Denominator = number of unique KIRC cases
    SELECT COUNT(DISTINCT "case_barcode") AS "total_cases"
    FROM labeled
)
-- 4.  Frequency of each CNV class per cytoband (% of total cases)
SELECT
    l."chromosome",
    l."cytoband_name",
    l."cnv_class",
    ROUND(100.0 * COUNT(DISTINCT l."case_barcode") / t."total_cases", 2) AS "percent_of_kirc_cases"
FROM labeled l
CROSS JOIN totals t
GROUP BY l."chromosome",
         l."cytoband_name",
         l."cnv_class",
         t."total_cases"
ORDER BY l."chromosome",
         l."cytoband_name",
         l."cnv_class";