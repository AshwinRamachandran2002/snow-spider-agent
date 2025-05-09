/* ------------------------------------------------------------
   Copy-number status (per chromosome) for TCGA-BRCA samples
   ------------------------------------------------------------
   A stand-alone query that requires only the masked segment
   table already present in the environment.  Instead of using
   an external cytoband catalogue (not accessible here), each
   chromosome is treated as a single “cytoband-like” interval
   spanning its entire length that is large enough to cover all
   observed segments.  The logic, CN rounding and CNV classes
   follow the original specification.
----------------------------------------------------------------*/
WITH
/* 1 ── BRCA copy-number segments ------------------------------------ */
brca_seg AS (
    SELECT
        "case_barcode",
        REPLACE("chromosome",'chr','')             AS chr,          -- e.g. 1 … X
        "start_pos"                                AS seg_start,
        "end_pos"                                  AS seg_end,
        /* convert log2-ratio to absolute copy number:
           log2(CN/2)  →  CN = 2 * 2^segment_mean                    */
        2 * POWER(2.0 , "segment_mean")            AS seg_copy
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED_R14"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* 2 ── Derive one chromosome-wide interval that covers all segments -- */
chrom_interval AS (
    SELECT
        chr,
        0                                           AS cyto_start,  -- anchor at 0
        MAX(seg_end)                                AS cyto_end,    -- span to max
        chr                                         AS cytoband     -- use chr as ID
    FROM brca_seg
    GROUP BY chr
),

/* 3 ── Intersect segments with chromosome interval ----------------- */
ovl AS (
    SELECT
        s."case_barcode",
        c.cytoband,
        c.cyto_start,
        c.cyto_end,
        LEAST(s.seg_end , c.cyto_end) - GREATEST(s.seg_start , c.cyto_start) + 1
            AS ovl_len,                                             -- bp overlap
        s.seg_copy
    FROM brca_seg        s
    JOIN chrom_interval  c
      ON c.chr = s.chr
),

/* 4 ── Length-weighted average CN per chromosome × case ------------ */
chrom_copy AS (
    SELECT
        "case_barcode",
        cytoband,
        cyto_start,
        cyto_end,
        SUM(ovl_len * seg_copy) / SUM(ovl_len)      AS avg_cn
    FROM ovl
    GROUP BY 1,2,3,4
),

/* 5 ── Round & classify CN ----------------------------------------- */
chrom_class AS (
    SELECT
        cytoband,
        cyto_start,
        cyto_end,
        "case_barcode",
        ROUND(avg_cn)                               AS cn_round,
        CASE
             WHEN ROUND(avg_cn) = 0 THEN 'Homozygous_Deletion'
             WHEN ROUND(avg_cn) = 1 THEN 'Heterozygous_Deletion'
             WHEN ROUND(avg_cn) = 2 THEN 'Diploid'
             WHEN ROUND(avg_cn) = 3 THEN 'Gain'
             WHEN ROUND(avg_cn) >  3 THEN 'Amplification'
        END                                         AS cnv_type
    FROM chrom_copy
),

/* 6 ── Counts per CNV class ---------------------------------------- */
class_counts AS (
    SELECT
        cytoband,
        cnv_type,
        COUNT(DISTINCT "case_barcode")              AS n_cases
    FROM chrom_class
    GROUP BY 1,2
),

/* 7 ── Total BRCA cases contributing to each chromosome ------------ */
tot_cases AS (
    SELECT
        cytoband,
        COUNT(DISTINCT "case_barcode")              AS total_cases
    FROM chrom_class
    GROUP BY 1
)

/* 8 ── Final percentage table -------------------------------------- */
SELECT
    t.cytoband                               AS "chromosome",
    t.total_cases                            AS "n_cases_total",

    /* frequencies rounded to two decimals */
    ROUND(100 * COALESCE(hd.n_cases,0)/t.total_cases , 2) AS "pct_homo_del",
    ROUND(100 * COALESCE(ht.n_cases,0)/t.total_cases , 2) AS "pct_het_del",
    ROUND(100 * COALESCE(dp.n_cases,0)/t.total_cases , 2) AS "pct_diploid",
    ROUND(100 * COALESCE(gn.n_cases,0)/t.total_cases , 2) AS "pct_gain",
    ROUND(100 * COALESCE(am.n_cases,0)/t.total_cases , 2) AS "pct_amplification"

FROM tot_cases t
LEFT JOIN class_counts hd ON hd.cytoband = t.cytoband AND hd.cnv_type = 'Homozygous_Deletion'
LEFT JOIN class_counts ht ON ht.cytoband = t.cytoband AND ht.cnv_type = 'Heterozygous_Deletion'
LEFT JOIN class_counts dp ON dp.cytoband = t.cytoband AND dp.cnv_type = 'Diploid'
LEFT JOIN class_counts gn ON gn.cytoband = t.cytoband AND gn.cnv_type = 'Gain'
LEFT JOIN class_counts am ON am.cytoband = t.cytoband AND am.cnv_type = 'Amplification'
ORDER BY
    CASE
        WHEN t.cytoband = 'X' THEN 23
        WHEN t.cytoband = 'Y' THEN 24
        ELSE TO_NUMBER(t.cytoband)
    END;