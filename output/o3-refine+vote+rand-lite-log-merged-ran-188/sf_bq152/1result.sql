/* ---------------------------------------------------------------------------
   Fallback solution – cytoband annotation table is not present in the
   data warehouse.  Instead we compute copy-number summaries per
   chromosome for TCGA-BRCA using the masked CNV segments table alone.

   CNV TABLE :
        TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED"
   --------------------------------------------------------------------------- */

/* 1.  All BRCA CNV segments */
WITH brca_segments AS (
    SELECT  "case_barcode",
            "chromosome"                AS chr,
            "start_pos"                 AS seg_start,
            "end_pos"                   AS seg_end,
            "segment_mean"
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED"
    WHERE  "project_short_name" = 'TCGA-BRCA'
),

/* 2.  Distinct list of BRCA cases (used for denominator) */
brca_cases AS (
    SELECT DISTINCT "case_barcode" FROM brca_segments
),

/* 3.  Length-weighted average CN per (case, chromosome) */
chrom_cn AS (
    SELECT   chr,
             "case_barcode",
             SUM( (seg_end - seg_start + 1) * "segment_mean")
             / SUM( seg_end - seg_start + 1 )          AS avg_cn
    FROM     brca_segments
    GROUP BY chr, "case_barcode"
),

/* 4.  Round & classify copy-number */
chrom_cn_class AS (
    SELECT  chr,
            "case_barcode",
            ROUND(avg_cn)                      AS rounded_cn,
            CASE
                WHEN ROUND(avg_cn) = 0 THEN '0 (HomDel)'
                WHEN ROUND(avg_cn) = 1 THEN '1 (HetDel)'
                WHEN ROUND(avg_cn) = 2 THEN '2 (Diploid)'
                WHEN ROUND(avg_cn) = 3 THEN '3 (Gain)'
                WHEN ROUND(avg_cn)  > 3 THEN '>3 (Amplif)'
                ELSE 'NA'
            END                                AS cnv_type
    FROM   chrom_cn
),

/* 5.  Percentage of cases in each CNV class per chromosome */
summary AS (
    SELECT  chr                                   AS chromosome,
            cnv_type,
            ROUND(
               100.0 * COUNT(DISTINCT "case_barcode")
               / (SELECT COUNT(*) FROM brca_cases)
            , 2)                                  AS pct_cases
    FROM    chrom_cn_class
    GROUP  BY chr, cnv_type
)

SELECT chromosome,
       cnv_type               AS "cnv_category",
       pct_cases              AS "brca_case_percentage"
FROM   summary
ORDER  BY chromosome , cnv_type;