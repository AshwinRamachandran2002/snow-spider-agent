/* ─────────────────────────────────────────────────────────────────────────────
   Copy‑number‑variation (CNV) landscape for TCGA‑BRCA
   ‑ overlap‑weighted average copy number for every case × chromosome
   ‑ CNV class (0–4) after rounding to the nearest integer
   ‑ frequency (%) of each CNV class across all BRCA cases
   NOTE:
     A ready‑made hg38 cytoband table is not available in this database, so the
     analysis is performed at full‑chromosome resolution (1‑22, X, Y).  Start/
     end positions correspond to the min‑start and max‑end positions observed
     among all BRCA copy‑number segments for each chromosome.
   ─────────────────────────────────────────────────────────────────────────── */

WITH
/* 1 ─ All masked copy‑number segments for TCGA‑BRCA cases ------------------- */
cn AS (
    SELECT
        "case_barcode",
        /* chromosomes are stored without the ‘chr’ prefix                       */
        "chromosome"      AS "chr",
        "start_pos"       AS "seg_start",
        "end_pos"         AS "seg_end",
        "segment_mean"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."COPY_NUMBER_SEGMENT_MASKED"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* 2 ─ Chromosome extents across all BRCA segments --------------------------- */
chrom_bounds AS (
    SELECT
        "chr",
        MIN("seg_start") AS "chr_start",
        MAX("seg_end")   AS "chr_end"
    FROM cn
    GROUP BY "chr"
),

/* 3 ─ Overlap‑weighted average CN per case × chromosome --------------------- */
case_chr_cn AS (
    SELECT
        c."case_barcode",
        c."chr",
        /* weighted average copy number: Σ(len*CN) / Σ(len)                      */
        SUM( (c."seg_end" - c."seg_start" + 1) *
             (POWER(2, c."segment_mean") * 2) ) /
        SUM(  c."seg_end" - c."seg_start" + 1 )     AS "avg_cn"
    FROM cn c
    GROUP BY
        c."case_barcode",
        c."chr"
),

/* 4 ─ CNV class assignment -------------------------------------------------- */
case_chr_type AS (
    SELECT
        cc."case_barcode",
        cc."chr",
        ROUND(cc."avg_cn")                       AS "rounded_cn",
        CASE
            WHEN ROUND(cc."avg_cn") = 0 THEN 'HomDel'
            WHEN ROUND(cc."avg_cn") = 1 THEN 'HetDel'
            WHEN ROUND(cc."avg_cn") = 2 THEN 'Diploid'
            WHEN ROUND(cc."avg_cn") = 3 THEN 'Gain'
            WHEN ROUND(cc."avg_cn") >  3 THEN 'Amplif'
        END                                     AS "cnv_type"
    FROM case_chr_cn cc
),

/* 5 ─ Total number of BRCA cases (denominator) ------------------------------ */
tot AS ( SELECT COUNT(DISTINCT "case_barcode") AS "n_cases" FROM cn )

/* 6 ─ Frequency of each CNV class per chromosome ---------------------------- */
SELECT
    cb."chr"                        AS "chromosome",
    cb."chr_start"                  AS "region_start",
    cb."chr_end"                    AS "region_end",

    ROUND(100 * SUM(CASE WHEN ct."cnv_type" = 'HomDel' THEN 1 ELSE 0 END)
               / t."n_cases", 2)    AS "pct_hom_del",
    ROUND(100 * SUM(CASE WHEN ct."cnv_type" = 'HetDel' THEN 1 ELSE 0 END)
               / t."n_cases", 2)    AS "pct_het_del",
    ROUND(100 * SUM(CASE WHEN ct."cnv_type" = 'Diploid' THEN 1 ELSE 0 END)
               / t."n_cases", 2)    AS "pct_diploid",
    ROUND(100 * SUM(CASE WHEN ct."cnv_type" = 'Gain'    THEN 1 ELSE 0 END)
               / t."n_cases", 2)    AS "pct_gain",
    ROUND(100 * SUM(CASE WHEN ct."cnv_type" = 'Amplif'  THEN 1 ELSE 0 END)
               / t."n_cases", 2)    AS "pct_amplification"

FROM chrom_bounds cb
LEFT JOIN case_chr_type ct
       ON cb."chr" = ct."chr"
CROSS JOIN tot t
GROUP BY
    cb."chr", cb."chr_start", cb."chr_end", t."n_cases"
ORDER BY
    CASE
        WHEN UPPER(cb."chr") = 'X' THEN 23
        WHEN UPPER(cb."chr") = 'Y' THEN 24
        ELSE TRY_TO_NUMBER(cb."chr")
    END;