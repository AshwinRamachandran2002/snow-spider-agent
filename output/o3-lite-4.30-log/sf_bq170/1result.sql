/*--------------------------------------------------------------------
Breast‑cancer (TCGA‑BRCA) cytoband‑level CNV frequencies – Release 23
--------------------------------------------------------------------*/
WITH
/* 1.  Copy‑number segments for BRCA cases ---------------------------------*/
seg AS (
    SELECT  "case_barcode",
            "chromosome",
            "start_pos",
            "end_pos",
            "copy_number"
    FROM    "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE   "project_short_name" = 'TCGA-BRCA'
),

/* 2.  Cytoband coordinates (hg38) -----------------------------------------*/
cb AS (
    SELECT  "cytoband_name",
            "chromosome",
            "hg38_start",
            "hg38_stop"
    FROM    "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
),

/* 3.  Base‑pair overlap between every cytoband and every segment ----------*/
overlaps AS (
    SELECT
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        seg."case_barcode",
        /* intersection length in bp */
        GREATEST(
            0,
            LEAST(cb."hg38_stop", seg."end_pos")
          - GREATEST(cb."hg38_start", seg."start_pos")
        )                                       AS ovlp_bp,
        seg."copy_number"                       AS seg_copy_number
    FROM cb
    JOIN seg
      ON cb."chromosome" = seg."chromosome"
     AND LEAST(cb."hg38_stop", seg."end_pos") > GREATEST(cb."hg38_start", seg."start_pos")
),

/* 4.  Overlap‑weighted, rounded copy number per cytoband‑case -------------*/
weighted_cn AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        ROUND( SUM(ovlp_bp * seg_copy_number)
             / NULLIF(SUM(ovlp_bp), 0) )        AS rounded_cn
    FROM overlaps
    GROUP BY "cytoband_name","hg38_start","hg38_stop","case_barcode"
),

/* 5.  Map rounded copy number to CNV class --------------------------------*/
classified AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        CASE
            WHEN rounded_cn = 0 THEN 'homozygous_deletion'
            WHEN rounded_cn = 1 THEN 'heterozygous_deletion'
            WHEN rounded_cn = 2 THEN 'diploid'
            WHEN rounded_cn = 3 THEN 'gain'
            WHEN rounded_cn > 3 THEN 'amplification'
        END                                AS cnv_class
    FROM weighted_cn
),

/* 6.  Total number of distinct BRCA cases ---------------------------------*/
total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM   seg
),

/* 7.  Case counts per CNV class & cytoband --------------------------------*/
freq_counts AS (
    SELECT
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop",
        SUM(IFF(cnv_class = 'homozygous_deletion', 1, 0)) AS homdel,
        SUM(IFF(cnv_class = 'heterozygous_deletion',1, 0)) AS hetdel,
        SUM(IFF(cnv_class = 'diploid',             1, 0)) AS diploid,
        SUM(IFF(cnv_class = 'gain',                1, 0)) AS gain,
        SUM(IFF(cnv_class = 'amplification',       1, 0)) AS amplification
    FROM   classified c
    GROUP BY c."cytoband_name", c."hg38_start", c."hg38_stop"
)

/* 8.  Convert counts to percentages ---------------------------------------*/
SELECT
    f."cytoband_name"                                          AS cytoband,
    f."hg38_start"                                             AS "start",
    f."hg38_stop"                                              AS "end",
    ROUND(100.0 * f.homdel        / t.n_cases, 2)              AS homozygous_deletion_pct,
    ROUND(100.0 * f.hetdel        / t.n_cases, 2)              AS heterozygous_deletion_pct,
    ROUND(100.0 * f.diploid       / t.n_cases, 2)              AS diploid_pct,
    ROUND(100.0 * f.gain          / t.n_cases, 2)              AS gain_pct,
    ROUND(100.0 * f.amplification / t.n_cases, 2)              AS amplification_pct
FROM   freq_counts f
CROSS  JOIN total_cases t
ORDER  BY f."cytoband_name";