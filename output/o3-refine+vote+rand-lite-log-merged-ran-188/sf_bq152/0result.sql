/*  Chromosome-level copy-number status for all TCGA-BRCA cases
    ------------------------------------------------------------------
    1)  Pull masked copy-number segments for TCGA-BRCA.
        – convert log2 segment_mean to absolute copy-number estimate
          CN  = 2*2^segment_mean   (then round to nearest integer)
    2)  For every (case, chromosome) compute a length-weighted
        average copy number from all segments belonging to that
        chromosome for that case.
    3)  Round to nearest integer and classify CNV:
           0 → homdel
           1 → hetloss
           2 → diploid
           3 → gain
          >3 → amp
    4)  Count how many BRCA cases fall into each CNV class for
        every chromosome and report the percentages (2-decimals).
*/
WITH brca_seg AS (                               -- 1. pull segments
    SELECT
        "case_barcode",
        REGEXP_REPLACE("chromosome",'chr','')      AS "chrom",
        "start_pos",
        "end_pos",
        "segment_mean",
        -- estimated absolute CN (rounded) for each segment
        ROUND( 2 * POWER(2 , "segment_mean") )     AS "seg_cn",
        ("end_pos" - "start_pos" + 1)              AS "seg_len"
    FROM TCGA_HG38_DATA_V0."TCGA_HG38_DATA_V0"."COPY_NUMBER_SEGMENT_MASKED"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
chr_cn AS (                                      -- 2. weighted-mean CN / case / chr
    SELECT
        "case_barcode",
        "chrom",
        MIN("start_pos")                       AS "chr_start",
        MAX("end_pos")                         AS "chr_end",
        SUM("seg_cn" * "seg_len") / SUM("seg_len") AS "avg_cn"
    FROM brca_seg
    GROUP BY "case_barcode", "chrom"
),
classified AS (                                 -- 3. round & classify
    SELECT
        "case_barcode",
        "chrom"                     AS "chromosome",
        "chr_start",
        "chr_end",
        ROUND("avg_cn")             AS "cn_round",
        CASE
            WHEN ROUND("avg_cn") = 0 THEN 'homdel'
            WHEN ROUND("avg_cn") = 1 THEN 'hetloss'
            WHEN ROUND("avg_cn") = 2 THEN 'diploid'
            WHEN ROUND("avg_cn") = 3 THEN 'gain'
            WHEN ROUND("avg_cn") > 3 THEN 'amp'
            ELSE 'unknown'
        END                         AS "cnv_type"
    FROM chr_cn
),
tot_cases AS (                                 -- total # BRCA cases
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases FROM classified
)
SELECT
    "chromosome",
    "chr_start",
    "chr_end",
    /* percentage of BRCA cases in each CNV class (2-decimals) */
    ROUND( 100 * COUNT_IF("cnv_type" = 'homdel')  / t.n_cases , 2) AS homdel_pct,
    ROUND( 100 * COUNT_IF("cnv_type" = 'hetloss') / t.n_cases , 2) AS hetloss_pct,
    ROUND( 100 * COUNT_IF("cnv_type" = 'diploid') / t.n_cases , 2) AS diploid_pct,
    ROUND( 100 * COUNT_IF("cnv_type" = 'gain')    / t.n_cases , 2) AS gain_pct,
    ROUND( 100 * COUNT_IF("cnv_type" = 'amp')     / t.n_cases , 2) AS amp_pct
FROM classified
CROSS JOIN tot_cases t
GROUP BY "chromosome", "chr_start", "chr_end", t.n_cases
ORDER BY LPAD("chromosome", 3, '0')::STRING   -- sort chr1..chr22,X,Y
;