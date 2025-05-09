/*---------------------------------------------------------------------------
  Copy‑number landscape per cytoband for TCGA‑BRCA (GDC release 23, hg38)
---------------------------------------------------------------------------*/
WITH
/* 1. All BRCA cases -------------------------------------------------------*/
"brca_cases" AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
/* 2. BRCA copy‑number segments -------------------------------------------*/
"segments" AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
/* 3. hg38 cytobands -------------------------------------------------------*/
"cytoband" AS (
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
),
/* 4. Segment × cytoband overlaps -----------------------------------------*/
"overlaps" AS (
    SELECT
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        sg."case_barcode",
        sg."copy_number",
        LEAST(cb."hg38_stop", sg."end_pos")
          - GREATEST(cb."hg38_start", sg."start_pos")        AS "ovlp_len"
    FROM "segments" sg
    JOIN "cytoband" cb
      ON cb."chromosome" = sg."chromosome"
    WHERE LEAST(cb."hg38_stop", sg."end_pos")
          - GREATEST(cb."hg38_start", sg."start_pos") > 0
),
/* 5. Weighted mean copy‑number per (case, cytoband) -----------------------*/
"band_cn_per_case" AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        ROUND( SUM("ovlp_len" * "copy_number") / SUM("ovlp_len") ) AS "cn_rounded"
    FROM "overlaps"
    GROUP BY
        "cytoband_name","hg38_start","hg38_stop","case_barcode"
),
/* 6. Classify CNV type ----------------------------------------------------*/
"band_cnv_per_case" AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        CASE
            WHEN "cn_rounded" = 0 THEN 'Homozygous Deletion'
            WHEN "cn_rounded" = 1 THEN 'Heterozygous Deletion'
            WHEN "cn_rounded" = 2 THEN 'Diploid'
            WHEN "cn_rounded" = 3 THEN 'Gain'
            ELSE                      'Amplification'
        END AS "cnv_type"
    FROM "band_cn_per_case"
),
/* 7. Total number of BRCA cases ------------------------------------------*/
"tot" AS ( SELECT COUNT(*) AS "n_cases" FROM "brca_cases" )

/* 8. Frequency of each CNV class per cytoband -----------------------------*/
SELECT
    cb."cytoband_name",
    cb."hg38_start",
    cb."hg38_stop",

    ROUND( 100.0 * SUM( CASE WHEN bc."cnv_type" = 'Homozygous Deletion'   THEN 1 ELSE 0 END )
           / MAX(t."n_cases"), 2) AS "homozygous_deletion_pct",

    ROUND( 100.0 * SUM( CASE WHEN bc."cnv_type" = 'Heterozygous Deletion' THEN 1 ELSE 0 END )
           / MAX(t."n_cases"), 2) AS "heterozygous_deletion_pct",

    ROUND( 100.0 * SUM( CASE WHEN bc."cnv_type" = 'Diploid'               THEN 1 ELSE 0 END )
           / MAX(t."n_cases"), 2) AS "diploid_pct",

    ROUND( 100.0 * SUM( CASE WHEN bc."cnv_type" = 'Gain'                  THEN 1 ELSE 0 END )
           / MAX(t."n_cases"), 2) AS "gain_pct",

    ROUND( 100.0 * SUM( CASE WHEN bc."cnv_type" = 'Amplification'         THEN 1 ELSE 0 END )
           / MAX(t."n_cases"), 2) AS "amplification_pct"

FROM "cytoband" cb
LEFT JOIN "band_cnv_per_case" bc
       ON  cb."cytoband_name" = bc."cytoband_name"
       AND cb."hg38_start"    = bc."hg38_start"
       AND cb."hg38_stop"     = bc."hg38_stop"
CROSS JOIN "tot" t
GROUP BY
    cb."cytoband_name",
    cb."hg38_start",
    cb."hg38_stop"
ORDER BY
    cb."cytoband_name";