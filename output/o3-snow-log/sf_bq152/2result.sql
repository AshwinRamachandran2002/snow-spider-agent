/*-----------------------------------------------------------
  Copy-number-variation (CNV) frequencies per chromosome
  for TCGA-BRCA copy-number data (masked segments, hg38).
  -----------------------------------------------------------
  AVAILABLE TABLES
      TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED"
          • columns:  "case_barcode"  "chromosome"
                      "start_pos"     "end_pos"
                      "segment_mean"  …
  METHOD
      1.  For every BRCA segment:  absolute copy number ≈ 2 × 2^(segment_mean).
      2.  For each (case, chromosome):
              length-weighted mean CN  →  rounded to nearest integer.
      3.  CN rounded-value → CNV class:
              0 = HomDel , 1 = HetDel , 2 = Diploid ,
              3 = Gain   , >3 = Amplification.
      4.  Count cases per class for each chromosome and
          express as % of all BRCA cases with segment data.
-----------------------------------------------------------*/
WITH
/* 1 ── BRCA segments with absolute CN and length */
brca_seg AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        ( "end_pos" - "start_pos" + 1 )                     AS seg_len,
        2 * POWER( 2, "segment_mean" )                      AS abs_cn     -- est. copy #
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
/* 2 ── length-weighted mean CN per (case, chr) */
case_chr_cn AS (
    SELECT
        "case_barcode",
        "chromosome",
        ROUND( SUM( seg_len * abs_cn ) / SUM( seg_len ) )   AS rounded_cn
    FROM brca_seg
    GROUP BY "case_barcode", "chromosome"
),
/* 3 ── CNV category assignment */
case_chr_cnv AS (
    SELECT
        "case_barcode",
        "chromosome",
        CASE
            WHEN rounded_cn = 0 THEN 'Homozygous Deletion'
            WHEN rounded_cn = 1 THEN 'Heterozygous Deletion'
            WHEN rounded_cn = 2 THEN 'Diploid'
            WHEN rounded_cn = 3 THEN 'Gain'
            WHEN rounded_cn > 3 THEN 'Amplification'
            ELSE 'Unknown'
        END AS cnv_type
    FROM case_chr_cn
),
/* 4 ── counts per chromosome */
chr_counts AS (
    SELECT
        "chromosome",
        COUNT( DISTINCT "case_barcode" )                                         AS n_cases_chr,
        SUM( CASE WHEN cnv_type = 'Homozygous Deletion'  THEN 1 END )            AS n_homdel,
        SUM( CASE WHEN cnv_type = 'Heterozygous Deletion' THEN 1 END )           AS n_hetdel,
        SUM( CASE WHEN cnv_type = 'Diploid'               THEN 1 END )           AS n_diploid,
        SUM( CASE WHEN cnv_type = 'Gain'                  THEN 1 END )           AS n_gain,
        SUM( CASE WHEN cnv_type = 'Amplification'         THEN 1 END )           AS n_amp
    FROM case_chr_cnv
    GROUP BY "chromosome"
),
/* 5 ── total BRCA cases with segment data */
tot AS (
    SELECT COUNT( DISTINCT "case_barcode" ) AS total_cases
    FROM brca_seg
)
/* 6 ── final frequency table */
SELECT
    c."chromosome",
    ROUND( 100.0 * n_homdel / t.total_cases, 2 )   AS pct_homdel,
    ROUND( 100.0 * n_hetdel / t.total_cases, 2 )   AS pct_hetdel,
    ROUND( 100.0 * n_diploid / t.total_cases, 2 )  AS pct_diploid,
    ROUND( 100.0 * n_gain   / t.total_cases, 2 )   AS pct_gain,
    ROUND( 100.0 * n_amp    / t.total_cases, 2 )   AS pct_amplification
FROM chr_counts c
CROSS JOIN tot t
ORDER BY
    CASE 
        WHEN TRY_TO_NUMBER(c."chromosome") IS NULL THEN 100  -- X/Y last
        ELSE TRY_TO_NUMBER(c."chromosome")
    END,
    c."chromosome";