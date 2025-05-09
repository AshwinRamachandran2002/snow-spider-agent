/* -----------------------------------------------------------------
   Copy-number status per cytoband for TCGA-BRCA (GDC release 23)
   -----------------------------------------------------------------*/

WITH
/* 1)  All R23 copy-number segments for TCGA-BRCA cases              */
seg AS (
    SELECT
        "case_barcode",
        "chromosome",          -- values like ‘chr1’, ‘chr2’, …, ‘chrX’
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* 2)  Intersect every segment with every cytoband on the same chr,
       keeping only rows that actually overlap                       */
overlaps AS (
    SELECT
        s."case_barcode",
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop",
        /* overlap length (bp)                                         */
        LEAST(s."end_pos",   c."hg38_stop")
      - GREATEST(s."start_pos", c."hg38_start") + 1    AS overlap_len,
        s."copy_number"
    FROM seg  s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38  c
         ON s."chromosome" = c."chromosome"
    WHERE LEAST(s."end_pos",   c."hg38_stop")
        - GREATEST(s."start_pos", c."hg38_start") + 1 > 0   -- retain only overlaps
),

/* 3)  Weighted-average copy number for every (case, cytoband)        */
per_case_cytoband AS (
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        /* weighted average, then round to nearest whole copy number   */
        ROUND( SUM(overlap_len * "copy_number")
             / NULLIF(SUM(overlap_len),0) )         AS rounded_cn
    FROM overlaps
    GROUP BY
        "case_barcode", "cytoband_name", "hg38_start", "hg38_stop"
),

/* 4)  Translate the rounded copy number to a CNV class               */
per_case_class AS (
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        CASE
            WHEN rounded_cn = 0          THEN 'HOMO_DEL'     -- homozygous deletion
            WHEN rounded_cn = 1          THEN 'HETERO_DEL'   -- heterozygous deletion
            WHEN rounded_cn = 2          THEN 'DIPLOID'      -- normal
            WHEN rounded_cn = 3          THEN 'GAIN'         -- single gain
            WHEN rounded_cn > 3          THEN 'AMPLIFICATION'
        END AS cnv_type
    FROM per_case_cytoband
),

/* 5)  Total number of TCGA-BRCA cases present in R23                 */
total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM   seg
)

/* 6)  Frequency of each CNV class per cytoband                       */
SELECT
    p."cytoband_name"                         AS cytoband,
    p."hg38_start"                            AS band_start,
    p."hg38_stop"                             AS band_stop,

    /* percentages, rounded to two decimals                            */
    ROUND( 100.0 * SUM( CASE WHEN p.cnv_type = 'HOMO_DEL'      THEN 1 END )
           / t.n_cases , 2)  AS pct_homozygous_deletion,

    ROUND( 100.0 * SUM( CASE WHEN p.cnv_type = 'HETERO_DEL'    THEN 1 END )
           / t.n_cases , 2)  AS pct_heterozygous_deletion,

    ROUND( 100.0 * SUM( CASE WHEN p.cnv_type = 'DIPLOID'       THEN 1 END )
           / t.n_cases , 2)  AS pct_normal_diploid,

    ROUND( 100.0 * SUM( CASE WHEN p.cnv_type = 'GAIN'          THEN 1 END )
           / t.n_cases , 2)  AS pct_gain,

    ROUND( 100.0 * SUM( CASE WHEN p.cnv_type = 'AMPLIFICATION' THEN 1 END )
           / t.n_cases , 2)  AS pct_amplification

FROM per_case_class  p
CROSS JOIN total_cases t
GROUP BY
    p."cytoband_name", p."hg38_start", p."hg38_stop", t.n_cases
ORDER BY
    p."cytoband_name"    -- alphabetical order of cytobands
;