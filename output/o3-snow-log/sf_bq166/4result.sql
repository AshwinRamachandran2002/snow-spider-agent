/*-----------------------------------------------------------
  Cytoband-level CNV class frequencies (percentage of cases)
  for the TCGA-KIRC cohort – hg38 allelic segmentation data
-----------------------------------------------------------*/
WITH kirc_segments AS (      -- keep only KIRC rows & required IDs
    SELECT
        COALESCE(seg."case_gdc_id", seg."sample_barcode") AS "case_id",
        seg."chromosome",
        seg."start_pos",
        seg."end_pos",
        seg."copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 seg
    WHERE seg."project_short_name" = 'TCGA-KIRC'
),

max_cn_per_band AS (         -- max copy-number per case × cytoband
    SELECT
        ks."case_id",
        band."chromosome",
        band."cytoband_name",
        MAX(ks."copy_number") AS "max_copy_number"
    FROM kirc_segments ks
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38 band
      ON band."chromosome" = ks."chromosome"
     AND ks."start_pos"   <= band."hg38_stop"
     AND ks."end_pos"     >= band."hg38_start"
    GROUP BY
        ks."case_id",
        band."chromosome",
        band."cytoband_name"
),

labelled AS (                -- translate max CN into categorical classes
    SELECT
        m."case_id",
        m."chromosome",
        m."cytoband_name",
        CASE
            WHEN m."max_copy_number" > 3 THEN 'Amplification'
            WHEN m."max_copy_number" = 3 THEN 'Gain'
            WHEN m."max_copy_number" = 2 THEN 'Normal'
            WHEN m."max_copy_number" = 1 THEN 'Het_Del'
            WHEN m."max_copy_number" = 0 THEN 'Hom_Del'
        END AS "cnv_class"
    FROM max_cn_per_band m
),

totals AS (                  -- total number of distinct KIRC cases
    SELECT COUNT(DISTINCT ks."case_id") AS "total_cases"
    FROM kirc_segments ks
),

band_class_counts AS (       -- #cases per cytoband × class
    SELECT
        l."chromosome",
        l."cytoband_name",
        l."cnv_class",
        COUNT(DISTINCT l."case_id") AS "case_count"
    FROM labelled l
    GROUP BY
        l."chromosome",
        l."cytoband_name",
        l."cnv_class"
)

SELECT
    bcc."chromosome",
    bcc."cytoband_name",
    bcc."cnv_class",
    100.0 * bcc."case_count" / t."total_cases" AS "frequency_pct"
FROM band_class_counts bcc
CROSS JOIN totals t
ORDER BY                                    -- sort numerically by chromosome
    CASE
        WHEN bcc."chromosome" IN ('chrX','X') THEN 23
        WHEN bcc."chromosome" IN ('chrY','Y') THEN 24
        ELSE TO_NUMBER(REGEXP_REPLACE(bcc."chromosome", '^chr', ''))
    END,
    bcc."cytoband_name",
    bcc."cnv_class";