/*  ---------------------------------------------------------------
    Cytoband-level CNV frequency profile for all TCGA-BRCA cases
    (GDC Release-23 allele-specific copy-number segments, hg38)
    --------------------------------------------------------------- */
WITH
-- 1.  All allele-specific CN segments for TCGA-BRCA
segments AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

-- 2.  hg38 cytoband coordinate reference
bands AS (
    SELECT
        "cytoband_name",
        "chromosome",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
),

-- 3.  Base-pair overlaps between every segment and every cytoband
overlaps AS (
    SELECT
        s."case_barcode",
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop",
        /* length of intersection in bp */
        GREATEST(
            0,
            LEAST(b."hg38_stop", s."end_pos") -
            GREATEST(b."hg38_start", s."start_pos")
        )                                              AS "ovl_bp",
        /* copy-number × bp for weighted average      */
        GREATEST(
            0,
            LEAST(b."hg38_stop", s."end_pos") -
            GREATEST(b."hg38_start", s."start_pos")
        ) * s."copy_number"                            AS "ovl_cn"
    FROM segments s
    JOIN bands    b
      ON s."chromosome" = b."chromosome"
    WHERE GREATEST(
            0,
            LEAST(b."hg38_stop", s."end_pos") -
            GREATEST(b."hg38_start", s."start_pos")
          ) > 0           -- keep only positive overlaps
),

-- 4.  Overlap-weighted, rounded CN for each (case × cytoband)
per_case_band AS (
    SELECT
        "case_barcode",
        "cytoband_name",
        MIN("hg38_start")                               AS "band_start",
        MAX("hg38_stop")                                AS "band_stop",
        ROUND( SUM("ovl_cn") / NULLIF(SUM("ovl_bp"),0) ) AS "rounded_cn"
    FROM overlaps
    GROUP BY "case_barcode", "cytoband_name"
),

-- 5.  Frequency of CNV classes across all cases for every cytoband
summary AS (
    SELECT
        "cytoband_name",
        MIN("band_start")                               AS "band_start",
        MAX("band_stop")                                AS "band_stop",
        COUNT(*)                                        AS "n_cases",
        ROUND( COUNT_IF("rounded_cn" = 0) * 100.0 / COUNT(*), 2) AS "homdel_pct",
        ROUND( COUNT_IF("rounded_cn" = 1) * 100.0 / COUNT(*), 2) AS "hetdel_pct",
        ROUND( COUNT_IF("rounded_cn" = 2) * 100.0 / COUNT(*), 2) AS "diploid_pct",
        ROUND( COUNT_IF("rounded_cn" = 3) * 100.0 / COUNT(*), 2) AS "gain_pct",
        ROUND( COUNT_IF("rounded_cn" > 3) * 100.0 / COUNT(*), 2) AS "amp_pct"
    FROM per_case_band
    GROUP BY "cytoband_name"
)

-- 6.  Final report
SELECT
    "cytoband_name",
    "band_start",
    "band_stop",
    "n_cases",
    "homdel_pct",
    "hetdel_pct",
    "diploid_pct",
    "gain_pct",
    "amp_pct"
FROM summary
ORDER BY "cytoband_name";