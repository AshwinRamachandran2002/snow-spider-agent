/*---------------------------------------------------------------
  CNV frequencies for TCGA-BRCA (GDC Release-23, hg38 coordinates)
----------------------------------------------------------------*/

WITH /* 1) copy-number segments for the project ----------------*/
segments AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* 2) list of BRCA cases ---------------------------------------*/
cases AS (
    SELECT DISTINCT "case_barcode" FROM segments
),

/* 3) cytoband coordinates (hg38) -------------------------------*/
cytobands AS (
    SELECT
        "cytoband_name",
        "chromosome",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),

/* 4) every (cytoband × case) combination -----------------------*/
band_case AS (
    SELECT
        cb."cytoband_name",
        cb."chromosome",
        cb."hg38_start",
        cb."hg38_stop",
        c."case_barcode"
    FROM cytobands cb
    CROSS JOIN cases c
),

/* 5) per-segment overlap length within each cytoband -----------*/
overlaps AS (
    SELECT
        bc."cytoband_name",
        bc."chromosome",
        bc."hg38_start",
        bc."hg38_stop",
        bc."case_barcode",
        s."copy_number",
        /* positive overlap length (bp) */
        LEAST(bc."hg38_stop", s."end_pos")
          - GREATEST(bc."hg38_start", s."start_pos")  AS overlap_len
    FROM band_case bc
    JOIN segments  s
      ON s."case_barcode" = bc."case_barcode"
     AND s."chromosome"   = bc."chromosome"
     AND LEAST(bc."hg38_stop", s."end_pos")
       > GREATEST(bc."hg38_start", s."start_pos")    /* ensure overlap */
),

/* 6) overlap-weighted, rounded copy number per band & case -----*/
weighted_cn AS (
    SELECT
        bc."cytoband_name",
        bc."chromosome",
        bc."hg38_start",
        bc."hg38_stop",
        bc."case_barcode",
        /* if no segment overlaps the band, assume normal diploid (2) */
        CASE
            WHEN SUM(o.overlap_len) > 0 THEN
                 ROUND(
                     SUM(o.overlap_len * o."copy_number")
                     / SUM(o.overlap_len)
                 )
            ELSE 2
        END AS rounded_cn
    FROM band_case bc
    LEFT JOIN overlaps o
      ON  o."cytoband_name" = bc."cytoband_name"
      AND o."case_barcode"  = bc."case_barcode"
    GROUP BY
        bc."cytoband_name",
        bc."chromosome",
        bc."hg38_start",
        bc."hg38_stop",
        bc."case_barcode"
),

/* 7) total number of BRCA cases --------------------------------*/
total_cases AS (
    SELECT COUNT(*) AS total_cases FROM cases
)

/* 8) cytoband-level CNV frequency table ------------------------*/
SELECT
    w."cytoband_name",
    w."chromosome",
    w."hg38_start",
    w."hg38_stop",

    /* frequency (%) of each CNV class, rounded to two decimals */
    ROUND(100.0 * SUM(CASE WHEN w.rounded_cn = 0 THEN 1 ELSE 0 END)
                / t.total_cases, 2)  AS homozygous_deletion_pct,

    ROUND(100.0 * SUM(CASE WHEN w.rounded_cn = 1 THEN 1 ELSE 0 END)
                / t.total_cases, 2)  AS heterozygous_deletion_pct,

    ROUND(100.0 * SUM(CASE WHEN w.rounded_cn = 2 THEN 1 ELSE 0 END)
                / t.total_cases, 2)  AS diploid_pct,

    ROUND(100.0 * SUM(CASE WHEN w.rounded_cn = 3 THEN 1 ELSE 0 END)
                / t.total_cases, 2)  AS gain_pct,

    ROUND(100.0 * SUM(CASE WHEN w.rounded_cn >= 4 THEN 1 ELSE 0 END)
                / t.total_cases, 2)  AS amplification_pct

FROM weighted_cn w
CROSS JOIN total_cases t
GROUP BY
    w."cytoband_name",
    w."chromosome",
    w."hg38_start",
    w."hg38_stop",
    t.total_cases
ORDER BY
    w."chromosome" NULLS LAST,
    w."hg38_start" NULLS LAST;