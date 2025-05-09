/* -----------------------------------------------------------------
   TCGA-BRCA chromosome-level copy-number category frequencies
   using masked CNV segments  (COPY_NUMBER_SEGMENT_MASKED_R14)
------------------------------------------------------------------*/

WITH
/* 1 ── BRCA CNV segments -------------------------------------- */
SEG AS (
    SELECT  
        "case_barcode"                              AS CASE_BARCODE,
        "chromosome"                                AS CHR,
        "start_pos"                                 AS SEG_START,
        "end_pos"                                   AS SEG_END,
        POWER(2 , "segment_mean") * 2               AS SEG_CN          -- absolute CN
    FROM  TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED_R14"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* 2 ── treat each whole chromosome as one “band” -------------- */
CHROM_BAND AS (
    SELECT  
        CHR,
        1                                           AS BAND_START,
        MAX(SEG_END)                                AS BAND_END,
        CHR                                         AS BAND_NAME
    FROM  SEG
    GROUP BY CHR
),

/* 3 ── intersect segments with chromosome bands --------------- */
OVL AS (
    SELECT  
        B.BAND_NAME,
        B.BAND_START,
        B.BAND_END,
        S.CASE_BARCODE,
        LEAST(S.SEG_END , B.BAND_END)
      - GREATEST(S.SEG_START , B.BAND_START) + 1    AS OVL_LEN,
        S.SEG_CN
    FROM  SEG  S
    JOIN  CHROM_BAND B
      ON  S.CHR = B.CHR
),

/* 4 ── length-weighted mean CN per (case,chromosome) ---------- */
CASE_CHR_CN AS (
    SELECT  
        BAND_NAME,
        BAND_START,
        BAND_END,
        CASE_BARCODE,
        ROUND( SUM(OVL_LEN * SEG_CN) / NULLIF(SUM(OVL_LEN),0) )  AS CN_ROUND
    FROM  OVL
    GROUP BY BAND_NAME, BAND_START, BAND_END, CASE_BARCODE
),

/* 5 ── assign CNV class --------------------------------------- */
CASE_CHR_CLASS AS (
    SELECT  
        BAND_NAME,
        BAND_START,
        BAND_END,
        CASE_BARCODE,
        CASE
             WHEN CN_ROUND = 0 THEN 'HomDel'
             WHEN CN_ROUND = 1 THEN 'HetDel'
             WHEN CN_ROUND = 2 THEN 'Diploid'
             WHEN CN_ROUND = 3 THEN 'Gain'
             ELSE                'Amplif'
        END  AS CNV_CLASS
    FROM  CASE_CHR_CN
),

/* 6 ── total number of unique BRCA cases ---------------------- */
TOT AS (
    SELECT COUNT(DISTINCT CASE_BARCODE) AS N_CASES
    FROM   SEG
)

/* 7 ── frequency (%) of each CNV class per chromosome --------- */
SELECT  
    C.BAND_NAME       AS "chromosome",
    C.BAND_START      AS "start_bp",
    C.BAND_END        AS "end_bp",

    ROUND(100.0 * SUM(CASE WHEN CNV_CLASS = 'HomDel' THEN 1 END) 
          / T.N_CASES , 2)   AS "pct_homdel",

    ROUND(100.0 * SUM(CASE WHEN CNV_CLASS = 'HetDel' THEN 1 END) 
          / T.N_CASES , 2)   AS "pct_hetdel",

    ROUND(100.0 * SUM(CASE WHEN CNV_CLASS = 'Diploid' THEN 1 END) 
          / T.N_CASES , 2)   AS "pct_diploid",

    ROUND(100.0 * SUM(CASE WHEN CNV_CLASS = 'Gain'    THEN 1 END) 
          / T.N_CASES , 2)   AS "pct_gain",

    ROUND(100.0 * SUM(CASE WHEN CNV_CLASS = 'Amplif'  THEN 1 END) 
          / T.N_CASES , 2)   AS "pct_amplif"

FROM            CASE_CHR_CLASS  C
CROSS JOIN      TOT             T
GROUP BY        C.BAND_NAME, C.BAND_START, C.BAND_END, T.N_CASES
ORDER BY        C.BAND_NAME;