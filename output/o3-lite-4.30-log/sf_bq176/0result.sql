WITH
/* cytoband coordinates for 15q11 on chromosome 15 (hg38) */
band AS (
    SELECT
        "hg38_start" AS band_start,
        "hg38_stop"  AS band_stop
    FROM  "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" ILIKE '15q11%'          -- 15q11, 15q11.1, 15q11.2 …
),
/* copy‑number segments for TCGA‑LAML on chromosome 15 (hg38) */
seg AS (
    SELECT *
    FROM  "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02"
    WHERE "project_short_name" = 'TCGA-LAML'
      AND "chromosome" = '15'
),
/* segments that overlap the 15q11 band and their exact overlap length */
overlaps AS (
    SELECT
        s."case_barcode",
        GREATEST(s."start_pos", b.band_start) AS ov_start,
        LEAST(  s."end_pos",   b.band_stop )  AS ov_end,
        s."segment_mean"
    FROM  seg AS s
    JOIN  band AS b
      ON  s."start_pos" <= b.band_stop
      AND s."end_pos"   >= b.band_start
),
/* weighted copy‑number contribution per overlapping segment */
weights AS (
    SELECT
        "case_barcode",
        (ov_end - ov_start + 1)                       AS overlap_bp,
        "segment_mean",
        "segment_mean" * (ov_end - ov_start + 1)      AS weighted_cn
    FROM  overlaps
)
/* final weighted‑average copy number per case (top 10 highest) */
SELECT
    "case_barcode",
    ROUND(SUM(weighted_cn) / SUM(overlap_bp), 4) AS "weighted_avg_copy_number_15q11"
FROM   weights
GROUP  BY "case_barcode"
ORDER  BY "weighted_avg_copy_number_15q11" DESC NULLS LAST,
          "case_barcode"
LIMIT 10;