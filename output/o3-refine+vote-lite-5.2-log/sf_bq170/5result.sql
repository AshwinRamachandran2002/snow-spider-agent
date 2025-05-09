/* -------------------------------------------------------------------------
   Breast‑cancer (TCGA‑BRCA) copy‑number landscape   –   GDC Release 23
---------------------------------------------------------------------------*/
WITH
/* --- cytoband coordinates (hg38) -------------------------------------- */
cytobands AS (
    SELECT
        "cytoband_name"                        AS cytoband,
        "chromosome",                          /* e.g.  ‘chr1’ */
        "hg38_start"::NUMBER                  AS cyto_start,
        "hg38_stop" ::NUMBER                  AS cyto_stop
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),

/* --- copy‑number segments for TCGA‑BRCA, release 23 ------------------- */
brca_segments AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos"    ::NUMBER  AS seg_start,
        "end_pos"      ::NUMBER  AS seg_end,
        "copy_number"  ::NUMBER  AS cn
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* --- number of distinct BRCA cases ----------------------------------- */
case_count AS (
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM brca_segments
),

/* --- per‑case / cytoband weighted‑average CN -------------------------- */
cyto_case_cn AS (
    SELECT
        cb.cytoband,
        cb.cyto_start,
        cb.cyto_stop,
        seg."case_barcode",
        /* weighted average CN for the overlapping part */
        SUM(
            GREATEST(
                0,
                LEAST(cb.cyto_stop , seg.seg_end)
              - GREATEST(cb.cyto_start, seg.seg_start)
              + 1
            ) * seg.cn
        )
        / NULLIF(
            SUM(
                GREATEST(
                    0,
                    LEAST(cb.cyto_stop , seg.seg_end)
                  - GREATEST(cb.cyto_start, seg.seg_start)
                  + 1
                )
            ),
            0
        )                                             AS avg_cn
    FROM cytobands cb
    JOIN brca_segments seg
      ON cb."chromosome" = seg."chromosome"
     AND LEAST(cb.cyto_stop , seg.seg_end) >= GREATEST(cb.cyto_start , seg.seg_start)
    GROUP BY
        cb.cytoband,
        cb.cyto_start,
        cb.cyto_stop,
        seg."case_barcode"
),

/* --- round & classify ------------------------------------------------- */
cyto_case_class AS (
    SELECT
        cytoband,
        cyto_start,
        cyto_stop,
        "case_barcode",
        ROUND(avg_cn)                    AS rounded_cn,
        CASE ROUND(avg_cn)
             WHEN 0 THEN 'Homozygous Deletion'
             WHEN 1 THEN 'Heterozygous Deletion'
             WHEN 2 THEN 'Diploid'
             WHEN 3 THEN 'Gain'
             ELSE      'Amplification'
        END                              AS cnv_type
    FROM cyto_case_cn
)

/* --- frequency of each CNV class per cytoband ------------------------- */
SELECT
    cytoband                                   AS "CYTOBAND",
    cyto_start                                 AS "CYTO_START",
    cyto_stop                                  AS "CYTO_STOP",

    ROUND(100.0 * SUM(IFF(cnv_type = 'Homozygous Deletion',1,0))
          / MAX(cc.n_cases) , 2)               AS "HOMOZYGOUS_DEL_%",

    ROUND(100.0 * SUM(IFF(cnv_type = 'Heterozygous Deletion',1,0))
          / MAX(cc.n_cases) , 2)               AS "HETEROZYGOUS_DEL_%",

    ROUND(100.0 * SUM(IFF(cnv_type = 'Diploid',1,0))
          / MAX(cc.n_cases) , 2)               AS "DIPLOID_%",

    ROUND(100.0 * SUM(IFF(cnv_type = 'Gain',1,0))
          / MAX(cc.n_cases) , 2)               AS "GAIN_%",

    ROUND(100.0 * SUM(IFF(cnv_type = 'Amplification',1,0))
          / MAX(cc.n_cases) , 2)               AS "AMPLIFICATION_%"

FROM cyto_case_class
CROSS JOIN case_count cc
GROUP BY
    cytoband,
    cyto_start,
    cyto_stop
ORDER BY
    cytoband;