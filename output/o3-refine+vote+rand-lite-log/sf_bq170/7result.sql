/*---------------------------------------------------------------
   CNV distribution on cytobands for TCGA‑BRCA (GDC release 23)
----------------------------------------------------------------*/
WITH
/* cytoband co‑ordinates (hg38) */
bands AS (
    SELECT
        "chromosome"                 AS band_chr,     -- e.g. 'chr1'
        "cytoband_name"              AS band_name,    -- e.g. '1p36'
        "hg38_start"                 AS band_start,
        "hg38_stop"                  AS band_stop
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),

/* allelic masked copy‑number segments for TCGA‑BRCA, release 23 */
segments AS (
    SELECT
        "case_barcode",
        "chromosome"                 AS seg_chr,      -- already prefixed with 'chr'
        "start_pos"                  AS seg_start,
        "end_pos"                    AS seg_stop,
        "copy_number"                AS copy_number
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* base‑pair overlap between every cytoband and intersecting segment */
overlaps AS (
    SELECT
        s."case_barcode",
        b.band_name,
        b.band_start,
        b.band_stop,
        /* overlapping base pairs */
        GREATEST(
            0,
            LEAST(s.seg_stop , b.band_stop) - GREATEST(s.seg_start , b.band_start) + 1
        )                                                AS ov_len,
        s.copy_number
    FROM segments s
    JOIN bands   b
      ON b.band_chr = s.seg_chr
     AND s.seg_stop  >= b.band_start
     AND s.seg_start <= b.band_stop
),

/* weighted average CN for each (case, cytoband) */
band_cn AS (
    SELECT
        "case_barcode",
        band_name,
        band_start,
        band_stop,
        SUM(ov_len * copy_number) / NULLIF(SUM(ov_len),0) AS avg_cn
    FROM overlaps
    GROUP BY "case_barcode", band_name, band_start, band_stop
),

/* round & classify CNV type */
band_cnv AS (
    SELECT
        "case_barcode",
        band_name,
        band_start,
        band_stop,
        ROUND(avg_cn)                                    AS cn_rounded,
        CASE
            WHEN ROUND(avg_cn) = 0 THEN 'Homozygous Deletion'
            WHEN ROUND(avg_cn) = 1 THEN 'Heterozygous Deletion'
            WHEN ROUND(avg_cn) = 2 THEN 'Diploid'
            WHEN ROUND(avg_cn) = 3 THEN 'Gain'
            WHEN ROUND(avg_cn) >  3 THEN 'Amplification'
            ELSE 'Unclassified'
        END                                              AS cnv_type
    FROM band_cn
),

/* counts of CNV categories per cytoband */
band_counts AS (
    SELECT
        band_name,
        band_start,
        band_stop,
        COUNT(DISTINCT "case_barcode")                           AS n_cases,
        COUNT_IF(cnv_type = 'Homozygous Deletion')               AS n_homdel,
        COUNT_IF(cnv_type = 'Heterozygous Deletion')             AS n_het_del,
        COUNT_IF(cnv_type = 'Diploid')                           AS n_diploid,
        COUNT_IF(cnv_type = 'Gain')                              AS n_gain,
        COUNT_IF(cnv_type = 'Amplification')                     AS n_amp
    FROM band_cnv
    GROUP BY band_name, band_start, band_stop
)

/* convert to percentages (two decimals) */
SELECT
    band_name                                     AS "CYTOBAND",
    band_start                                    AS "BAND_START",
    band_stop                                     AS "BAND_STOP",
    ROUND(100.0 * n_homdel / n_cases, 2)          AS "%_HOMO_DEL",
    ROUND(100.0 * n_het_del / n_cases, 2)         AS "%_HETERO_DEL",
    ROUND(100.0 * n_diploid / n_cases, 2)         AS "%_DIPLOID",
    ROUND(100.0 * n_gain    / n_cases, 2)         AS "%_GAIN",
    ROUND(100.0 * n_amp     / n_cases, 2)         AS "%_AMPLIFICATION"
FROM band_counts
ORDER BY "CYTOBAND";