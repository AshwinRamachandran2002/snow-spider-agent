WITH band_level AS (   -- highest copy‑number per cytoband for each TCGA‑KIRC case
    SELECT
        seg."case_barcode",
        band."chromosome",
        band."cytoband_name"               AS "cytoband",
        MAX(seg."copy_number")             AS "max_cn"
    FROM  TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 seg
    JOIN  TCGA_MITELMAN.PROD.CYTOBANDS_HG38 band
          ON  seg."chromosome" = band."chromosome"
          AND seg."end_pos"   >= band."hg38_start"
          AND seg."start_pos" <= band."hg38_stop"
    WHERE seg."project_short_name" = 'TCGA-KIRC'
    GROUP BY
        seg."case_barcode",
        band."chromosome",
        band."cytoband_name"
),
totals AS (            -- distinct‑case count per cytoband
    SELECT
        "chromosome",
        "cytoband",
        COUNT(DISTINCT "case_barcode") AS "total_cases"
    FROM band_level
    GROUP BY
        "chromosome",
        "cytoband"
),
freq AS (              -- case counts in each CNV category
    SELECT
        "chromosome",
        "cytoband",
        SUM(CASE WHEN "max_cn" > 3 THEN 1 ELSE 0 END) AS amp_cases,
        SUM(CASE WHEN "max_cn" = 3 THEN 1 ELSE 0 END) AS gain_cases,
        SUM(CASE WHEN "max_cn" = 1 THEN 1 ELSE 0 END) AS het_del_cases,
        SUM(CASE WHEN "max_cn" = 0 THEN 1 ELSE 0 END) AS homo_del_cases,
        SUM(CASE WHEN "max_cn" = 2 THEN 1 ELSE 0 END) AS normal_cases
    FROM band_level
    GROUP BY
        "chromosome",
        "cytoband"
)
SELECT
    f."chromosome",
    f."cytoband",
    ROUND(100.0 * amp_cases      / t."total_cases", 4) AS amplification_pct,
    ROUND(100.0 * gain_cases     / t."total_cases", 4) AS gain_pct,
    ROUND(100.0 * het_del_cases  / t."total_cases", 4) AS heterozygous_deletion_pct,
    ROUND(100.0 * homo_del_cases / t."total_cases", 4) AS homozygous_deletion_pct,
    ROUND(100.0 * normal_cases   / t."total_cases", 4) AS normal_pct
FROM freq f
JOIN totals t
  ON f."chromosome" = t."chromosome"
 AND f."cytoband"   = t."cytoband"
ORDER BY
    f."chromosome",
    f."cytoband";