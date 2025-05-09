WITH
-- coordinates for cytoband 15q11 (all sub‑bands beginning with 15q11)
"CYTOBAND" AS (
    SELECT
        "hg38_start"      AS "cb_start",
        "hg38_stop"       AS "cb_stop",
        "chromosome"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome"      = 'chr15'
      AND "cytoband_name" ILIKE '15q11%'      -- 15q11, 15q11.1, 15q11.2 …
),
-- copy‑number segments from TCGA‑LAML on chr15
"SEG" AS (
    SELECT
        "case_barcode",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-LAML'
      AND "chromosome"         = 'chr15'
),
-- overlap each segment with the cytoband, keep only intersecting parts
"OVERLAP" AS (
    SELECT
        s."case_barcode",
        s."copy_number",
        GREATEST(s."start_pos", c."cb_start")        AS "ov_start",
        LEAST  (s."end_pos"  , c."cb_stop")          AS "ov_end"
    FROM "SEG" s
    JOIN "CYTOBAND" c
      ON s."start_pos" <= c."cb_stop"
     AND s."end_pos"   >= c."cb_start"
),
-- weighted average copy number per case within 15q11 (weight = overlap length)
"WEIGHTED" AS (
    SELECT
        "case_barcode",
        SUM( ("ov_end" - "ov_start" + 1) * "copy_number") AS "weighted_cn_sum",
        SUM(  "ov_end" - "ov_start" + 1)                  AS "weighted_len"
    FROM "OVERLAP"
    GROUP BY "case_barcode"
),
-- rank cases by weighted average copy number (highest first)
"RANKED" AS (
    SELECT
        "case_barcode",
        "weighted_cn_sum" / "weighted_len"               AS "weighted_avg_cn",
        RANK() OVER (ORDER BY "weighted_cn_sum" / "weighted_len" DESC) AS "rnk"
    FROM "WEIGHTED"
)
-- return the case barcode(s) with the highest weighted average copy number
SELECT
    "case_barcode"
FROM "RANKED"
WHERE "rnk" = 1
ORDER BY "case_barcode";