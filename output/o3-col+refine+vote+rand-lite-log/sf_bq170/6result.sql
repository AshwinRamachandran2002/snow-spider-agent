/* ------------------------------------------------------------------
   Copy-Number-Variation landscape across all cytobands in TCGA-BRCA
   Release-23 allelic CN-segments – Snowflake SQL
------------------------------------------------------------------ */
WITH brca_cases AS (          -- distinct BRCA cases present in R23 table
    SELECT DISTINCT "case_barcode"
    FROM   TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE  "project_short_name" = 'TCGA-BRCA'
),
total_cases AS (              -- scalar # of BRCA cases for % calculation
    SELECT COUNT(*) AS n_cases
    FROM   brca_cases
),
/* ---------------------------------------------------------------
   1 row per <cytoband , case> containing the overlap-weighted,
   rounded copy number in that cytoband for the case
---------------------------------------------------------------- */
per_case_band AS (
    SELECT
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        s."case_barcode",
        /* weighted-average CN rounded to nearest integer */
        ROUND( SUM( (LEAST(cb."hg38_stop", s."end_pos")  -
                     GREATEST(cb."hg38_start", s."start_pos")) * s."copy_number")
              / NULLIF( SUM( LEAST(cb."hg38_stop", s."end_pos")  -
                              GREATEST(cb."hg38_start", s."start_pos")), 0) ) 
        AS "rounded_cn"
    FROM   TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                                   cb
    JOIN   TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
           ON cb."chromosome" = s."chromosome"
    WHERE  s."project_short_name" = 'TCGA-BRCA'
      AND  LEAST(cb."hg38_stop", s."end_pos") 
           > GREATEST(cb."hg38_start", s."start_pos")     -- keep positive overlap
    GROUP  BY cb."cytoband_name", cb."hg38_start", cb."hg38_stop", s."case_barcode"
),
/* ---------------------------------------------------------------
   Aggregate across cases → raw counts of each CNV class
---------------------------------------------------------------- */
band_counts AS (
    SELECT
        pcb."cytoband_name",
        pcb."hg38_start",
        pcb."hg38_stop",
        COUNT_IF(pcb."rounded_cn" = 0)        AS homdel_cnt,
        COUNT_IF(pcb."rounded_cn" = 1)        AS hetdel_cnt,
        COUNT_IF(pcb."rounded_cn" = 2)        AS diploid_cnt,
        COUNT_IF(pcb."rounded_cn" = 3)        AS gain_cnt,
        COUNT_IF(pcb."rounded_cn" > 3)        AS amp_cnt
    FROM   per_case_band pcb
    GROUP  BY pcb."cytoband_name", pcb."hg38_start", pcb."hg38_stop"
)
/* ---------------------------------------------------------------
   Final output – percentage of BRCA cases in each CNV category
---------------------------------------------------------------- */
SELECT
    bc."cytoband_name",
    bc."hg38_start",
    bc."hg38_stop",
    ROUND(100.0 * bc.homdel_cnt / (SELECT n_cases FROM total_cases), 2) AS "%homdel",
    ROUND(100.0 * bc.hetdel_cnt / (SELECT n_cases FROM total_cases), 2) AS "%het_del",
    ROUND(100.0 * bc.diploid_cnt / (SELECT n_cases FROM total_cases), 2) AS "%diploid",
    ROUND(100.0 * bc.gain_cnt    / (SELECT n_cases FROM total_cases), 2) AS "%gain",
    ROUND(100.0 * bc.amp_cnt     / (SELECT n_cases FROM total_cases), 2) AS "%amp"
FROM   band_counts bc
ORDER  BY bc."cytoband_name";