/*--------------------------------------------------------------
  Frequency of CNV sub-types per cytoband in TCGA-KIRC samples
----------------------------------------------------------------*/
WITH classify AS (           -- 1. max copy number per sample × cytoband
    SELECT
        COALESCE(s."sample_barcode", s."case_gdc_id")          AS "sample_id",
        s."chromosome",                                        -- e.g. chr1 … chr22, chrX, chrY
        b."cytoband_name",
        MAX(s."copy_number")                                   AS "max_copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                  b
          ON  s."chromosome" = b."chromosome"
         AND s."end_pos"   > b."hg38_start"      -- interval overlap
         AND s."start_pos" < b."hg38_stop"
    WHERE s."project_short_name" = 'TCGA-KIRC'
    GROUP BY
        COALESCE(s."sample_barcode", s."case_gdc_id"),
        s."chromosome",
        b."cytoband_name"
), labeled AS (            -- 2. convert max copy number to CNV class
    SELECT
        "sample_id",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN "max_copy_number" > 3 THEN 'Amplification'
            WHEN "max_copy_number" = 3 THEN 'Gain'
            WHEN "max_copy_number" = 2 THEN 'Normal'
            WHEN "max_copy_number" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_copy_number" = 0 THEN 'Homozygous Deletion'
        END                                                   AS "cnv_class"
    FROM classify
), totals AS (            -- 3. total number of distinct KIRC cases
    SELECT COUNT(DISTINCT "sample_id") AS "tot_cases"
    FROM   labeled
), freq AS (              -- 4. per-cytoband × class counts
    SELECT
        "chromosome",
        "cytoband_name",
        "cnv_class",
        COUNT(DISTINCT "sample_id") AS "n_cases"
    FROM   labeled
    GROUP BY
        "chromosome",
        "cytoband_name",
        "cnv_class"
)
-- 5. convert to percentage and order nicely
SELECT
    f."chromosome",
    f."cytoband_name",
    f."cnv_class",
    ROUND(f."n_cases" / t."tot_cases" * 100, 2) AS "frequency_percent"
FROM   freq   f
CROSS  JOIN totals t
ORDER BY
    CASE                                 -- numeric chromosome ordering
        WHEN f."chromosome" = 'chrX' THEN 23
        WHEN f."chromosome" = 'chrY' THEN 24
        ELSE TO_NUMBER(REPLACE(f."chromosome", 'chr', ''))
    END,
    f."cytoband_name",
    f."cnv_class";