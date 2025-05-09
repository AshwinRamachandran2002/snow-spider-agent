/*---------------------------------------------------------------------------
  Copy‑number landscape per cytoband in breast‑cancer (TCGA‑BRCA) – GDC R23
---------------------------------------------------------------------------*/
WITH
/* 1. Copy‑number segments for TCGA‑BRCA (release 23) -----------------------*/
relevant_cnv AS (
    SELECT  "case_barcode",
            "chromosome",
            "start_pos",
            "end_pos",
            "copy_number"   AS COPY_NUMBER          -- give case‑insensitive alias
    FROM    TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE   "project_short_name" = 'TCGA-BRCA'
),

/* 2. Join segments to cytobands and derive overlap -------------------------*/
overlaps AS (
    SELECT
        c."case_barcode",
        b."cytoband_name",
        b."chromosome",
        b."hg38_start",
        b."hg38_stop",
        /* overlap boundaries */
        GREATEST(b."hg38_start", c."start_pos")   AS ov_start,
        LEAST  (b."hg38_stop",  c."end_pos")      AS ov_end,
        c.COPY_NUMBER
    FROM   relevant_cnv                         c
    JOIN   TCGA_MITELMAN.PROD."CYTOBANDS_HG38"  b
      ON   b."chromosome" = c."chromosome"
),

/* 3. Keep true overlaps and length -----------------------------------------*/
valid AS (
    SELECT *,
           ov_end - ov_start            AS ov_len
    FROM   overlaps
    WHERE  ov_end > ov_start            -- positive overlap only
),

/* 4. Weighted average CN for each cytoband per case ------------------------*/
band_cn AS (
    SELECT
        "case_barcode",
        "cytoband_name",
        "chromosome",
        "hg38_start",
        "hg38_stop",
        ROUND( SUM(ov_len * COPY_NUMBER) / SUM(ov_len) ) AS rounded_cn
    FROM   valid
    GROUP  BY
        "case_barcode","cytoband_name",
        "chromosome","hg38_start","hg38_stop"
),

/* 5. Translate rounded CN to CNV category ----------------------------------*/
band_type AS (
    SELECT
        *,
        CASE rounded_cn
             WHEN 0 THEN 'Homozygous Deletion'
             WHEN 1 THEN 'Heterozygous Deletion'
             WHEN 2 THEN 'Diploid'
             WHEN 3 THEN 'Gain'
             ELSE        'Amplification'
        END AS cnv_type
    FROM   band_cn
),

/* 6. Total BRCA cases with data per cytoband -------------------------------*/
case_totals AS (
    SELECT  "cytoband_name",
            "chromosome",
            "hg38_start",
            "hg38_stop",
            COUNT(DISTINCT "case_barcode") AS total_cases
    FROM    band_type
    GROUP  BY "cytoband_name","chromosome","hg38_start","hg38_stop"
),

/* 7. Count of each CNV class per cytoband ----------------------------------*/
freq_raw AS (
    SELECT
        bt."cytoband_name",
        bt."chromosome",
        bt."hg38_start",
        bt."hg38_stop",
        bt.cnv_type,
        COUNT(DISTINCT bt."case_barcode") AS cases_with_type
    FROM   band_type bt
    GROUP BY bt."cytoband_name",bt."chromosome",
             bt."hg38_start",bt."hg38_stop",bt.cnv_type
)

/* 8. Final frequency table --------------------------------------------------*/
SELECT
    fr."cytoband_name"  AS "CYTOBAND",
    fr."chromosome"     AS "CHROMOSOME",
    fr."hg38_start"     AS "START_POS",
    fr."hg38_stop"      AS "END_POS",
    fr.cnv_type         AS "CNV_TYPE",
    ROUND(fr.cases_with_type * 100.0 / ct.total_cases , 2) AS "FREQUENCY_PERCENT"
FROM   freq_raw   fr
JOIN   case_totals ct
  ON   fr."cytoband_name" = ct."cytoband_name"
 AND   fr."chromosome"    = ct."chromosome"
 AND   fr."hg38_start"    = ct."hg38_start"
 AND   fr."hg38_stop"     = ct."hg38_stop"
ORDER BY fr."chromosome",
         fr."hg38_start",
         fr.cnv_type;