/*  Copy‑number landscape of TCGA‑BRCA (GDC Release‑23)
    – frequency of CNV classes per cytoband                                        */

WITH
/* -------------------------------------------------------------------------- */
/* 1.  All copy‑number segments for TCGA‑BRCA cases (Release‑23, allelic)      */
brca_segments AS (
    SELECT *
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* total number of BRCA cases (denominator for all percentages) -------------- */
total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM brca_segments
),

/* -------------------------------------------------------------------------- */
/* 2.  Overlap‑weighted copy‑number per (case × cytoband)                      */
per_case_band AS (
    SELECT
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop",
        s."case_barcode",

        /* weighted average CN  = Σ(overlap × CN) / Σ(overlap)                 */
        SUM( GREATEST(
                 0,
                 LEAST(b."hg38_stop",  s."end_pos")
               - GREATEST(b."hg38_start", s."start_pos")
             ) * s."copy_number"
        )  / NULLIF(
               SUM(
                   GREATEST(
                       0,
                       LEAST(b."hg38_stop",  s."end_pos")
                     - GREATEST(b."hg38_start", s."start_pos")
                   )
               ), 0
           )                                                AS weighted_cn
    FROM brca_segments               s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38 b
          ON s."chromosome" = b."chromosome"
    GROUP BY b."cytoband_name",
             b."hg38_start",
             b."hg38_stop",
             s."case_barcode"
    HAVING SUM(
               GREATEST(
                   0,
                   LEAST(b."hg38_stop",  s."end_pos")
                 - GREATEST(b."hg38_start", s."start_pos")
               )
           ) > 0                                    -- keep pairs with overlap
),

/* -------------------------------------------------------------------------- */
/* 3.  Round CN and assign CNV class per case × cytoband                       */
classified AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        CASE
            WHEN ROUND(weighted_cn) = 0 THEN 'HomDel'   -- homo‑deletion
            WHEN ROUND(weighted_cn) = 1 THEN 'HetDel'   -- hetero‑deletion
            WHEN ROUND(weighted_cn) = 2 THEN 'Diploid'  -- normal
            WHEN ROUND(weighted_cn) = 3 THEN 'Gain'     -- single gain
            WHEN ROUND(weighted_cn)  > 3 THEN 'Amp'     -- amplification
        END                                            AS cnv_class
    FROM per_case_band
)

/* -------------------------------------------------------------------------- */
/* 4.  Frequency (%) of each CNV class for every cytoband                      */
SELECT
    c."cytoband_name",
    c."hg38_start",
    c."hg38_stop",

    /* percentage of BRCA cases in each CNV class (rounded to 2 dp) ---------- */
    ROUND( SUM(CASE WHEN cnv_class = 'HomDel' THEN 1 ELSE 0 END)
           * 100.0 / tc.n_cases , 2)          AS "pct_homdel",

    ROUND( SUM(CASE WHEN cnv_class = 'HetDel' THEN 1 ELSE 0 END)
           * 100.0 / tc.n_cases , 2)          AS "pct_hetdel",

    ROUND( SUM(CASE WHEN cnv_class = 'Diploid' THEN 1 ELSE 0 END)
           * 100.0 / tc.n_cases , 2)          AS "pct_diploid",

    ROUND( SUM(CASE WHEN cnv_class = 'Gain'    THEN 1 ELSE 0 END)
           * 100.0 / tc.n_cases , 2)          AS "pct_gain",

    ROUND( SUM(CASE WHEN cnv_class = 'Amp'     THEN 1 ELSE 0 END)
           * 100.0 / tc.n_cases , 2)          AS "pct_amp"

FROM   classified               c
CROSS  JOIN total_cases         tc            -- provides n_cases scalar
GROUP  BY
       c."cytoband_name",
       c."hg38_start",
       c."hg38_stop",
       tc.n_cases
ORDER BY
       c."cytoband_name";