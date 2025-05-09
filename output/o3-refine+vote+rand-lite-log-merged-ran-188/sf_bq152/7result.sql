/* ---------------------------------------------------------------
   Chromosome-level CNV profile for TCGA-BRCA cases
-----------------------------------------------------------------*/
WITH brca_seg AS (          /* all BRCA copy-number segments    */
    SELECT  "case_barcode"  AS CASE_BARCODE,
            "chromosome"    AS CHROMOSOME,
            "start_pos"     AS START_POS,
            "end_pos"       AS END_POS,
            "segment_mean"  AS SEGMENT_MEAN
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.COPY_NUMBER_SEGMENT_MASKED
    WHERE  "project_short_name" = 'TCGA-BRCA'
),

/* derive extent of each chromosome from the data itself */
chromosome_bounds AS (
    SELECT  CHROMOSOME,
            1                              AS BAND_START,
            MAX(END_POS)                   AS BAND_END,
            CHROMOSOME                     AS BAND_NAME
    FROM    brca_seg
    GROUP BY CHROMOSOME
),

/* intersect every segment with its chromosome “band”            */
overlap AS (
    SELECT
        cb.BAND_NAME,
        cb.CHROMOSOME,
        cb.BAND_START,
        cb.BAND_END,
        bs.CASE_BARCODE,
        /* overlap length                                        */
        LEAST(bs.END_POS , cb.BAND_END) -
        GREATEST(bs.START_POS , cb.BAND_START) + 1          AS OV_LEN,
        /* absolute copy number of the segment                  */
        2 * POWER(2 , bs.SEGMENT_MEAN)                      AS ABS_CN,
        (cb.BAND_END - cb.BAND_START + 1)                   AS BAND_LEN
    FROM   chromosome_bounds cb
    JOIN   brca_seg         bs
          ON bs.CHROMOSOME = cb.CHROMOSOME
         AND bs.END_POS   >= cb.BAND_START
         AND bs.START_POS <= cb.BAND_END
),

/* length-weighted mean CN per (case × chromosome)               */
chr_case_cn AS (
    SELECT
        BAND_NAME, CHROMOSOME, BAND_START, BAND_END,
        CASE_BARCODE,
        ROUND( SUM(ABS_CN * OV_LEN) / MAX(BAND_LEN) )  AS ROUND_CN
    FROM   overlap
    GROUP  BY BAND_NAME, CHROMOSOME, BAND_START, BAND_END, CASE_BARCODE
),

/* convert rounded CN to discrete CNV class                      */
chr_case_class AS (
    SELECT *,
           CASE
             WHEN ROUND_CN = 0 THEN 'Homozygous Deletion'
             WHEN ROUND_CN = 1 THEN 'Heterozygous Deletion'
             WHEN ROUND_CN = 2 THEN 'Diploid'
             WHEN ROUND_CN = 3 THEN 'Gain'
             WHEN ROUND_CN  > 3 THEN 'Amplification'
             ELSE 'Unknown'
           END AS CNV_CLASS
    FROM   chr_case_cn
),

/* counts per chromosome                                          */
summary AS (
    SELECT
        BAND_NAME, CHROMOSOME, BAND_START, BAND_END,
        COUNT(DISTINCT CASE_BARCODE)                       AS N_CASES_CHR,
        COUNT_IF(CNV_CLASS = 'Homozygous Deletion')        AS N_HOMDEL,
        COUNT_IF(CNV_CLASS = 'Heterozygous Deletion')      AS N_HETDEL,
        COUNT_IF(CNV_CLASS = 'Diploid')                    AS N_DIPLOID,
        COUNT_IF(CNV_CLASS = 'Gain')                       AS N_GAIN,
        COUNT_IF(CNV_CLASS = 'Amplification')              AS N_AMP
    FROM   chr_case_class
    GROUP BY BAND_NAME, CHROMOSOME, BAND_START, BAND_END
),

tot AS (                      /* total number of BRCA cases      */
    SELECT COUNT(DISTINCT CASE_BARCODE) AS TOTAL_CASES
    FROM   brca_seg
)

/* ---------------------------  final report  ------------------- */
SELECT
    BAND_NAME   AS CHROMOSOME,
    BAND_START,
    BAND_END,
    ROUND(100.0 * N_HOMDEL / TOTAL_CASES , 2) AS PCT_HOMO_DEL,
    ROUND(100.0 * N_HETDEL / TOTAL_CASES , 2) AS PCT_HETERO_DEL,
    ROUND(100.0 * N_DIPLOID/ TOTAL_CASES , 2) AS PCT_DIPLOID,
    ROUND(100.0 * N_GAIN   / TOTAL_CASES , 2) AS PCT_GAIN,
    ROUND(100.0 * N_AMP    / TOTAL_CASES , 2) AS PCT_AMPLIFICATION
FROM   summary, tot
ORDER  BY CHROMOSOME;