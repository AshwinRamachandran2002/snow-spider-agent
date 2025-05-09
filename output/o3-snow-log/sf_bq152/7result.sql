/*-----------------------------------------------------------------
  Summarise copy-number status per chromosome in all TCGA-BRCA
  cases (masked segments only).  No external reference tables
  needed; everything comes from COPY_NUMBER_SEGMENT_MASKED.
------------------------------------------------------------------*/

WITH /* 1 ─ BRCA masked CNV segments ---------------------------*/
brca_seg AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos"                       AS seg_start,
        "end_pos"                         AS seg_end,
        "segment_mean",                   -- keep exact case
        ("end_pos" - "start_pos" + 1)     AS seg_len
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* 2 ─ Chromosome span (min/max) -------------------------------*/
chrom_bounds AS (
    SELECT
        "chromosome",
        MIN(seg_start) AS chr_start,
        MAX(seg_end)   AS chr_end
    FROM brca_seg
    GROUP BY "chromosome"
),

/* 3 ─ Length-weighted CN per (case, chromosome) ---------------*/
chr_case_cn AS (
    SELECT
        "case_barcode",
        "chromosome",
        ROUND(
            SUM(seg_len * "segment_mean") / NULLIF(SUM(seg_len),0)
        , 2)                              AS avg_cn
    FROM brca_seg
    GROUP BY
        "case_barcode",
        "chromosome"
),

/* 4 ─ Round & classify copy number ----------------------------*/
chr_case_class AS (
    SELECT
        "case_barcode",
        "chromosome",
        avg_cn,
        ROUND(avg_cn)                     AS rounded_cn,
        CASE
            WHEN ROUND(avg_cn) = 0 THEN 'HomoDel'
            WHEN ROUND(avg_cn) = 1 THEN 'HetDel'
            WHEN ROUND(avg_cn) = 2 THEN 'Diploid'
            WHEN ROUND(avg_cn) = 3 THEN 'Gain'
            WHEN ROUND(avg_cn)  > 3 THEN 'Amp'
            ELSE 'Unknown'
        END                               AS cnv_class
    FROM chr_case_cn
),

/* 5 ─ Number of distinct BRCA cases ---------------------------*/
nbr_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM brca_seg
)

/* 6 ─ Chromosome-level CNV frequency table --------------------*/
SELECT
    b."chromosome"  AS "chromosome",
    cb.chr_start    AS "chr_start",
    cb.chr_end      AS "chr_end",

    ROUND(100 * SUM(IFF(cnv_class = 'HomoDel',1,0)) / n.n_cases, 2) AS "pct_homodel",
    ROUND(100 * SUM(IFF(cnv_class = 'HetDel' ,1,0)) / n.n_cases, 2) AS "pct_hetdel",
    ROUND(100 * SUM(IFF(cnv_class = 'Diploid',1,0)) / n.n_cases, 2) AS "pct_diploid",
    ROUND(100 * SUM(IFF(cnv_class = 'Gain'   ,1,0)) / n.n_cases, 2) AS "pct_gain",
    ROUND(100 * SUM(IFF(cnv_class = 'Amp'    ,1,0)) / n.n_cases, 2) AS "pct_amp"

FROM chr_case_class  b
JOIN chrom_bounds    cb ON b."chromosome" = cb."chromosome"
CROSS JOIN nbr_cases n
GROUP BY
    b."chromosome",
    cb.chr_start,
    cb.chr_end,
    n.n_cases
ORDER BY
    TRY_TO_NUMBER(b."chromosome") NULLS LAST,  -- numeric chr first
    b."chromosome";