WITH
band AS (   -- cytoband coordinates (hg38)
    SELECT
        "cytoband_name"            AS "cytoband",
        "chromosome",
        "hg38_start"               AS "start",
        "hg38_stop"                AS "end"
    FROM  "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
),
seg AS (    -- copy‑number segments for TCGA‑BRCA (release 23)
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM  "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
weighted AS (   -- overlap‑weighted, rounded copy number per cytoband & case
    SELECT
        b."cytoband",
        b."start",
        b."end",
        s."case_barcode",
        ROUND(
            SUM(ovl_bp * s."copy_number") /
            NULLIF(SUM(ovl_bp), 0)
        ) AS "rounded_cn"
    FROM band b
    JOIN seg  s
      ON s."chromosome" = b."chromosome"
    -- overlap (bp) between the segment and the cytoband
    CROSS JOIN LATERAL (
        SELECT GREATEST(
                   0,
                   LEAST(b."end",  s."end_pos") -
                   GREATEST(b."start", s."start_pos")
               ) AS ovl_bp
    ) o
    WHERE o.ovl_bp > 0
    GROUP BY b."cytoband", b."start", b."end", s."case_barcode"
),
classified AS (   -- map rounded copy number to CNV class
    SELECT
        "cytoband",
        "start",
        "end",
        CASE
            WHEN "rounded_cn" = 0 THEN 'homdel'
            WHEN "rounded_cn" = 1 THEN 'hetdel'
            WHEN "rounded_cn" = 2 THEN 'diploid'
            WHEN "rounded_cn" = 3 THEN 'gain'
            WHEN "rounded_cn" > 3 THEN 'amp'
        END AS "cnv_class"
    FROM weighted
)
SELECT
    c."cytoband",
    c."start",
    c."end",
    ROUND(100.0 * COUNT_IF(c."cnv_class" = 'homdel') / COUNT(*), 2) AS "homozygous_deletion_pct",
    ROUND(100.0 * COUNT_IF(c."cnv_class" = 'hetdel') / COUNT(*), 2) AS "heterozygous_deletion_pct",
    ROUND(100.0 * COUNT_IF(c."cnv_class" = 'diploid') / COUNT(*), 2) AS "diploid_pct",
    ROUND(100.0 * COUNT_IF(c."cnv_class" = 'gain')    / COUNT(*), 2) AS "gain_pct",
    ROUND(100.0 * COUNT_IF(c."cnv_class" = 'amp')     / COUNT(*), 2) AS "amplification_pct"
FROM  classified c
GROUP BY c."cytoband", c."start", c."end"
ORDER BY c."cytoband";