/* -----------------------------------------------------------------
   Copy-number landscape of TCGA-BRCA cases at chromosome level
   ----------------------------------------------------------------- */

WITH brca_segs AS (     /* 1. masked CN segments for all TCGA-BRCA cases */
    SELECT  "case_barcode",
            "chromosome",
            "start_pos",
            "end_pos",
            "segment_mean",
            ("end_pos" - "start_pos" + 1)                              AS seg_len,
            2 * POWER(2, "segment_mean")                               AS abs_cn   -- absolute CN
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED_R14"
    WHERE  "project_short_name" = 'TCGA-BRCA'
),

total_cases AS (         /* 2. number of unique BRCA cases (scalar)  */
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM   brca_segs
),

chrom_case_cn AS (       /* 3. length-weighted CN per (case, chromosome) */
    SELECT  "case_barcode",
            "chromosome",
            SUM(abs_cn * seg_len) / SUM(seg_len)     AS avg_cn
    FROM    brca_segs
    GROUP BY "case_barcode", "chromosome"
),

chrom_case_type AS (     /* 4. round & classify CN state              */
    SELECT  "case_barcode",
            "chromosome",
            ROUND(avg_cn)                             AS rounded_cn,
            CASE
                WHEN ROUND(avg_cn) = 0 THEN 'HomDel'
                WHEN ROUND(avg_cn) = 1 THEN 'HetDel'
                WHEN ROUND(avg_cn) = 2 THEN 'Diploid'
                WHEN ROUND(avg_cn) = 3 THEN 'Gain'
                ELSE                       'Amplification'
            END                                       AS cnv_type
    FROM    chrom_case_cn
),

freqs AS (               /* 5. counts of each CNV class per chromosome */
    SELECT  "chromosome",
            SUM(CASE WHEN cnv_type = 'HomDel'        THEN 1 ELSE 0 END) AS n_homdel,
            SUM(CASE WHEN cnv_type = 'HetDel'        THEN 1 ELSE 0 END) AS n_hetdel,
            SUM(CASE WHEN cnv_type = 'Diploid'       THEN 1 ELSE 0 END) AS n_diploid,
            SUM(CASE WHEN cnv_type = 'Gain'          THEN 1 ELSE 0 END) AS n_gain,
            SUM(CASE WHEN cnv_type = 'Amplification' THEN 1 ELSE 0 END) AS n_amp
    FROM    chrom_case_type
    GROUP BY "chromosome"
)

SELECT  f."chromosome",
        ROUND(100.0 * f.n_homdel  / t.n_cases, 2) AS pct_homdel,
        ROUND(100.0 * f.n_hetdel  / t.n_cases, 2) AS pct_hetdel,
        ROUND(100.0 * f.n_diploid / t.n_cases, 2) AS pct_diploid,
        ROUND(100.0 * f.n_gain    / t.n_cases, 2) AS pct_gain,
        ROUND(100.0 * f.n_amp     / t.n_cases, 2) AS pct_amplification
FROM    freqs          f
CROSS JOIN total_cases t
ORDER BY 
    CASE                                        /* custom chromosome order */
        WHEN TRY_TO_NUMBER(f."chromosome") IS NOT NULL THEN TRY_TO_NUMBER(f."chromosome")
        WHEN f."chromosome" = 'X' THEN 23
        WHEN f."chromosome" = 'Y' THEN 24
        ELSE 25
    END;