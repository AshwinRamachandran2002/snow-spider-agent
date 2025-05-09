/*==============================================================
  Breast-cancer (TCGA-BRCA, GDC Release 23) cytoband-level CNV
  frequencies – Snowflake SQL
==============================================================*/
WITH
/*------------------------------------------------------------
  1.  Allelic copy-number segments for TCGA-BRCA cases
------------------------------------------------------------*/
brca_segments AS (
    SELECT
        "case_barcode",          -- TCGA case ID
        "chromosome",            -- e.g. ‘chr1’ … ‘chr22’, ‘chrX’
        "start_pos",
        "end_pos",
        "copy_number"            -- summed major + minor CN
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
/*------------------------------------------------------------
  2.  hg38 cytoband coordinates
------------------------------------------------------------*/
cytobands AS (
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
),
/*------------------------------------------------------------
  3.  Total number of BRCA cases (denominator for %)
------------------------------------------------------------*/
total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS total_n
    FROM brca_segments
),
/*------------------------------------------------------------
  4.  Overlap-weighted CN per (case × cytoband)
------------------------------------------------------------*/
band_case_cn AS (
    SELECT
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        bs."case_barcode",
        /* weighted average CN, then round to nearest integer */
        ROUND(
            SUM(
                CASE
                    /* length of intersection × CN */
                    WHEN LEAST(cb."hg38_stop", bs."end_pos")
                         >  GREATEST(cb."hg38_start", bs."start_pos")
                    THEN ( LEAST(cb."hg38_stop", bs."end_pos")
                         - GREATEST(cb."hg38_start", bs."start_pos") )
                         * bs."copy_number"
                    ELSE 0
                END
            )
            /
            NULLIF(
                /* total overlap length */
                SUM(
                    CASE
                        WHEN LEAST(cb."hg38_stop", bs."end_pos")
                             >  GREATEST(cb."hg38_start", bs."start_pos")
                        THEN ( LEAST(cb."hg38_stop", bs."end_pos")
                             - GREATEST(cb."hg38_start", bs."start_pos") )
                        ELSE 0
                    END
                ), 0
            )
        , 0)        AS "rounded_cn"
    FROM cytobands cb
    JOIN brca_segments bs
      ON cb."chromosome" = bs."chromosome"
     AND bs."end_pos"   > cb."hg38_start"   -- intervals overlap
     AND bs."start_pos" < cb."hg38_stop"
    GROUP BY
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        bs."case_barcode"
),
/*------------------------------------------------------------
  5.  Assign CNV type per (case × cytoband)
------------------------------------------------------------*/
band_case_class AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        "rounded_cn"                    AS "copy_number",
        CASE
            WHEN "rounded_cn" = 0 THEN 'Homozygous Deletion'
            WHEN "rounded_cn" = 1 THEN 'Heterozygous Deletion'
            WHEN "rounded_cn" = 2 THEN 'Diploid'
            WHEN "rounded_cn" = 3 THEN 'Gain'
            WHEN "rounded_cn" > 3 THEN 'Amplification'
            ELSE 'Unknown'
        END                             AS "cnv_type"
    FROM band_case_cn
    WHERE "rounded_cn" IS NOT NULL
),
/*------------------------------------------------------------
  6.  Cytoband-level frequency (%) of each CNV category
------------------------------------------------------------*/
band_frequencies AS (
    SELECT
        bcc."cytoband_name",
        bcc."hg38_start",
        bcc."hg38_stop",
        /* percentage of all BRCA cases, rounded to 2 dp */
        ROUND(
            SUM(CASE WHEN bcc."cnv_type" = 'Homozygous Deletion' THEN 1 ELSE 0 END)
            * 100.0 / tc.total_n , 2)     AS "pct_homozygous_deletion",
        ROUND(
            SUM(CASE WHEN bcc."cnv_type" = 'Heterozygous Deletion' THEN 1 ELSE 0 END)
            * 100.0 / tc.total_n , 2)     AS "pct_heterozygous_deletion",
        ROUND(
            SUM(CASE WHEN bcc."cnv_type" = 'Diploid' THEN 1 ELSE 0 END)
            * 100.0 / tc.total_n , 2)     AS "pct_diploid",
        ROUND(
            SUM(CASE WHEN bcc."cnv_type" = 'Gain' THEN 1 ELSE 0 END)
            * 100.0 / tc.total_n , 2)     AS "pct_gain",
        ROUND(
            SUM(CASE WHEN bcc."cnv_type" = 'Amplification' THEN 1 ELSE 0 END)
            * 100.0 / tc.total_n , 2)     AS "pct_amplification"
    FROM band_case_class bcc
    CROSS JOIN total_cases tc         -- for denominator
    GROUP BY
        bcc."cytoband_name",
        bcc."hg38_start",
        bcc."hg38_stop",
        tc.total_n
)
/*------------------------------------------------------------
  7.  Final result
------------------------------------------------------------*/
SELECT
    "cytoband_name",
    "hg38_start"   AS "cytoband_start",
    "hg38_stop"    AS "cytoband_end",
    "pct_homozygous_deletion",
    "pct_heterozygous_deletion",
    "pct_diploid",
    "pct_gain",
    "pct_amplification"
FROM band_frequencies
ORDER BY "cytoband_name" NULLS LAST;