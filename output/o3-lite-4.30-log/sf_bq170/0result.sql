/* -----------------------------------------------------------
   Copy‑number landscape per cytoband – TCGA‑BRCA (GDC Release 23)
   ----------------------------------------------------------- */

WITH
-- A) BRCA copy‑number segments (release 23, hg38)
seg AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

-- B) Cytoband coordinates (hg38)
cb AS (
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),

-- C) Segment‑band overlaps (>0 bp)
pairs AS (
    SELECT
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        seg."case_barcode",
        GREATEST(
            0,
            LEAST(cb."hg38_stop", seg."end_pos") -
            GREATEST(cb."hg38_start", seg."start_pos") + 1
        )                                   AS ov_bp,
        seg."copy_number"
    FROM cb
    JOIN seg
      ON cb."chromosome" = seg."chromosome"
    WHERE GREATEST(
              0,
              LEAST(cb."hg38_stop", seg."end_pos") -
              GREATEST(cb."hg38_start", seg."start_pos") + 1
          ) > 0
),

-- D) Weighted (rounded) copy number per (case, cytoband)
band_case AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        ROUND(SUM(ov_bp * "copy_number") / SUM(ov_bp)) AS rounded_cn
    FROM pairs
    GROUP BY
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode"
),

-- E) CNV class assignment
band_case_cls AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        rounded_cn,
        CASE
            WHEN rounded_cn = 0 THEN 'homozygous_deletion'
            WHEN rounded_cn = 1 THEN 'heterozygous_deletion'
            WHEN rounded_cn = 2 THEN 'diploid'
            WHEN rounded_cn = 3 THEN 'gain'
            ELSE                 'amplification'
        END AS cnv_type
    FROM band_case
),

-- F) Total BRCA cases with CNV data
total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM seg
),

-- G) Counts of CNV types per cytoband
freq AS (
    SELECT
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop",
        SUM(CASE WHEN b.cnv_type = 'homozygous_deletion'  THEN 1 ELSE 0 END) AS homo_del_cnt,
        SUM(CASE WHEN b.cnv_type = 'heterozygous_deletion' THEN 1 ELSE 0 END) AS het_del_cnt,
        SUM(CASE WHEN b.cnv_type = 'diploid'              THEN 1 ELSE 0 END) AS diploid_cnt,
        SUM(CASE WHEN b.cnv_type = 'gain'                 THEN 1 ELSE 0 END) AS gain_cnt,
        SUM(CASE WHEN b.cnv_type = 'amplification'        THEN 1 ELSE 0 END) AS amp_cnt
    FROM band_case_cls b
    GROUP BY
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop"
)

-- H) Final percentage report
SELECT
    f."cytoband_name"                                   AS cytoband,
    f."hg38_start"                                      AS "start",
    f."hg38_stop"                                       AS "end",
    ROUND(100.0 * f.homo_del_cnt / t.n_cases, 2)        AS homozygous_deletion_pct,
    ROUND(100.0 * f.het_del_cnt  / t.n_cases, 2)        AS heterozygous_deletion_pct,
    ROUND(100.0 * f.diploid_cnt  / t.n_cases, 2)        AS diploid_pct,
    ROUND(100.0 * f.gain_cnt     / t.n_cases, 2)        AS gain_pct,
    ROUND(100.0 * f.amp_cnt      / t.n_cases, 2)        AS amplification_pct
FROM freq f
CROSS JOIN total_cases t
ORDER BY cytoband;