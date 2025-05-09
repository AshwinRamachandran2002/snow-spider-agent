/* ---------------------------------------------------------------------------
   TCGA‑KIRC copy‑number frequencies per cytoband (hg38, allelic segments)
--------------------------------------------------------------------------- */
WITH total_cases AS (   -- denominator
    SELECT COUNT(DISTINCT "case_barcode") AS total_cases
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),
per_case_band AS (      -- max copy number for every (case, cytoband)
    SELECT
        s."case_barcode",
        b."chromosome",
        b."cytoband_name",
        MAX(s."copy_number") AS max_cn
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" b
      ON  s."chromosome" = b."chromosome"
     AND GREATEST(s."start_pos", b."hg38_start")
         <= LEAST(s."end_pos", b."hg38_stop")          -- segment overlaps band
    WHERE s."project_short_name" = 'TCGA-KIRC'
    GROUP BY s."case_barcode", b."chromosome", b."cytoband_name"
),
classified AS (         -- translate max_cn to categorical label
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN max_cn > 3 THEN 'Amplification'
            WHEN max_cn = 3 THEN 'Gain'
            WHEN max_cn = 2 THEN 'Normal'
            WHEN max_cn = 1 THEN 'Het_Del'
            WHEN max_cn = 0 THEN 'Hom_Del'
            ELSE 'Other'
        END AS cnv_class
    FROM per_case_band
),
summary AS (            -- count distinct cases of each class per cytoband
    SELECT
        "chromosome",
        "cytoband_name",
        COUNT(DISTINCT CASE WHEN cnv_class = 'Amplification' THEN "case_barcode" END) AS amp_n,
        COUNT(DISTINCT CASE WHEN cnv_class = 'Gain'          THEN "case_barcode" END) AS gain_n,
        COUNT(DISTINCT CASE WHEN cnv_class = 'Het_Del'       THEN "case_barcode" END) AS hetdel_n,
        COUNT(DISTINCT CASE WHEN cnv_class = 'Hom_Del'       THEN "case_barcode" END) AS homdel_n,
        COUNT(DISTINCT CASE WHEN cnv_class = 'Normal'        THEN "case_barcode" END) AS normal_n
    FROM classified
    GROUP BY "chromosome", "cytoband_name"
)
SELECT
    "chromosome"                                         AS chromosome,
    "cytoband_name"                                      AS cytoband,
    ROUND(amp_n   * 100.0 / total_cases, 4)              AS amplification_pct,
    ROUND(gain_n  * 100.0 / total_cases, 4)              AS gain_pct,
    ROUND(hetdel_n* 100.0 / total_cases, 4)              AS heterozygous_deletion_pct,
    ROUND(homdel_n* 100.0 / total_cases, 4)              AS homozygous_deletion_pct,
    ROUND(normal_n* 100.0 / total_cases, 4)              AS normal_pct
FROM summary, total_cases
ORDER BY
    -- numeric chromosome ordering 1‑22,X,Y
    CASE
        WHEN "chromosome" = 'chrX' THEN 23
        WHEN "chromosome" = 'chrY' THEN 24
        ELSE TRY_TO_NUMBER(REPLACE("chromosome",'chr',''))
    END,
    "cytoband_name";