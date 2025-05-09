/*------------------------------------------------------------
  Frequency of CNV sub-types (Amplification, Gain, Normal,
  Heterozygous- & Homozygous-Deletion) per cytoband in
  TCGA-KIRC, expressed as % of all KIRC cases.
------------------------------------------------------------*/
WITH total_cases AS (          -- # distinct TCGA-KIRC cases
    SELECT COUNT(DISTINCT "case_barcode") AS "total_cnt"
    FROM   TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE  "project_short_name" = 'TCGA-KIRC'
),
per_case_band AS (             -- max integer CN per case × cytoband
    SELECT
        s."case_barcode",
        c."chromosome",
        c."cytoband_name",
        MAX(s."copy_number")              AS "max_cn"
    FROM  TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    JOIN  TCGA_MITELMAN.PROD.CYTOBANDS_HG38                        c
          ON s."chromosome" = c."chromosome"
    WHERE s."project_short_name" = 'TCGA-KIRC'
      AND LEAST(s."end_pos",  c."hg38_stop")   -- keep only real overlaps
          > GREATEST(s."start_pos", c."hg38_start")
    GROUP BY
        s."case_barcode",
        c."chromosome",
        c."cytoband_name"
),
labeled AS (                   -- assign biological CNV class
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN "max_cn" > 3 THEN 'Amplification'
            WHEN "max_cn" = 3 THEN 'Gain'
            WHEN "max_cn" = 2 THEN 'Normal'
            WHEN "max_cn" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_cn" = 0 THEN 'Homozygous Deletion'
        END AS "cn_class"
    FROM per_case_band
)
SELECT
    l."chromosome",
    l."cytoband_name",
    l."cn_class",
    ROUND(100.0 * COUNT(DISTINCT l."case_barcode") / t."total_cnt", 2)
        AS "frequency_pct"
FROM   labeled      l
CROSS  JOIN total_cases t
GROUP  BY
    l."chromosome",
    l."cytoband_name",
    l."cn_class",
    t."total_cnt"
ORDER BY
    l."chromosome",
    l."cytoband_name",
    l."cn_class";