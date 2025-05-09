/*-----------------------------------------------------------
  Copy-number cytoband frequencies for TCGA-KIRC
-----------------------------------------------------------*/
WITH seg AS (  -- 1.  Keep only allele-specific CNV segments from TCGA-KIRC
    SELECT
        s."case_barcode",      -- unique case identifier
        s."chromosome",
        s."start_pos",
        s."end_pos",
        s."copy_number"
    FROM  "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"  s
    WHERE s."project_short_name" = 'TCGA-KIRC'
),

joined AS (     -- 2.  Locate every segment on its overlapping cytobands
    SELECT
        seg."case_barcode",
        seg."chromosome",
        cb."cytoband_name",
        seg."copy_number"
    FROM seg
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"  cb
      ON seg."chromosome" = cb."chromosome"
     AND seg."start_pos"  < cb."hg38_stop"
     AND seg."end_pos"    > cb."hg38_start"
),

per_case_band AS ( -- 3.  Maximum copy number per case × cytoband
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        MAX("copy_number") AS "max_copy"
    FROM joined
    GROUP BY
        "case_barcode",
        "chromosome",
        "cytoband_name"
),

classified AS (  -- 4.  Translate copy numbers into CNV categories
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
        END AS "cnv_class"
    FROM per_case_band
),

total_cases AS ( -- 5.  Number of distinct TCGA-KIRC cases
    SELECT COUNT(DISTINCT "case_barcode") AS "n_cases"
    FROM   per_case_band
)

/*-----------------------------------------------------------
  6.  Final frequency table
-----------------------------------------------------------*/
SELECT
    c."chromosome",
    c."cytoband_name",
    c."cnv_class",
    ROUND( COUNT(DISTINCT c."case_barcode") * 100.0
           / t."n_cases", 4)      AS "frequency_pct"
FROM classified  c
CROSS JOIN total_cases t
GROUP BY
    c."chromosome",
    c."cytoband_name",
    c."cnv_class",
    t."n_cases"
ORDER BY
    c."chromosome",
    c."cytoband_name",
    c."cnv_class";