WITH
-- all cytobands (hg38)
cytobands AS (
    SELECT
        "cytoband_name",
        "chromosome",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
),

-- copy‑number segments for breast‑cancer cases, release 23
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

-- compute bp‑overlap between every cytoband and every segment of the same chromosome
overlaps AS (
    SELECT
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        seg."case_barcode",
        seg."copy_number",
        LEAST(cb."hg38_stop", seg."end_pos")
          - GREATEST(cb."hg38_start", seg."start_pos")          AS overlap_len   -- bp
    FROM cytobands cb
    JOIN segments  seg
          ON cb."chromosome" = seg."chromosome"
         AND cb."hg38_start" < seg."end_pos"
         AND cb."hg38_stop"  > seg."start_pos"
    WHERE LEAST(cb."hg38_stop", seg."end_pos")
          - GREATEST(cb."hg38_start", seg."start_pos")  > 0
),

-- weighted‑average copy number per (case, cytoband)
weighted_cnv AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        ROUND( SUM(overlap_len * "copy_number") / SUM(overlap_len) )  AS rounded_cn
    FROM overlaps
    GROUP BY
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode"
),

-- classify rounded copy number into CNV categories
classified AS (
    SELECT
        w."cytoband_name",
        w."hg38_start",
        w."hg38_stop",
        w."case_barcode",
        CASE
            WHEN w.rounded_cn = 0 THEN 'Homozygous Deletion'
            WHEN w.rounded_cn = 1 THEN 'Heterozygous Deletion'
            WHEN w.rounded_cn = 2 THEN 'Normal Diploid'
            WHEN w.rounded_cn = 3 THEN 'Gain'
            WHEN w.rounded_cn > 3 THEN 'Amplification'
            ELSE 'Unknown'
        END AS cnv_type
    FROM weighted_cnv w
)

-- final frequency table: % of cases in each CNV class per cytoband
SELECT
    c."cytoband_name",
    c."hg38_start",
    c."hg38_stop",
    ROUND(100.0 * SUM(CASE WHEN c.cnv_type = 'Homozygous Deletion'   THEN 1 ELSE 0 END)
                 / COUNT(DISTINCT c."case_barcode"), 2) AS homozygous_deletion_pct,
    ROUND(100.0 * SUM(CASE WHEN c.cnv_type = 'Heterozygous Deletion' THEN 1 ELSE 0 END)
                 / COUNT(DISTINCT c."case_barcode"), 2) AS heterozygous_deletion_pct,
    ROUND(100.0 * SUM(CASE WHEN c.cnv_type = 'Normal Diploid'        THEN 1 ELSE 0 END)
                 / COUNT(DISTINCT c."case_barcode"), 2) AS normal_diploid_pct,
    ROUND(100.0 * SUM(CASE WHEN c.cnv_type = 'Gain'                  THEN 1 ELSE 0 END)
                 / COUNT(DISTINCT c."case_barcode"), 2) AS gain_pct,
    ROUND(100.0 * SUM(CASE WHEN c.cnv_type = 'Amplification'         THEN 1 ELSE 0 END)
                 / COUNT(DISTINCT c."case_barcode"), 2) AS amplification_pct
FROM classified c
GROUP BY
    c."cytoband_name",
    c."hg38_start",
    c."hg38_stop"
ORDER BY
    c."cytoband_name";