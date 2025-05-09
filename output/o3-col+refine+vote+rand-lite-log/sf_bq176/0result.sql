/*  Identify TCGA-LAML cases with the highest weighted-average copy number
    across cytoband 15q11 (and any sub-bands) on chromosome 15            */

WITH band AS (   -- collapse the entire 15q11 cytoband span to one interval
    SELECT
        MIN("hg38_start") AS "band_start",
        MAX("hg38_stop")  AS "band_end"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome"      = 'chr15'
      AND "cytoband_name" ILIKE '15q11%'
),
ovl AS (          -- segment ↔ cytoband intersection
    SELECT
        s."case_barcode",
        GREATEST(s."start_pos", b."band_start") AS "ov_start",
        LEAST(  s."end_pos",   b."band_end")    AS "ov_end",
        s."copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    CROSS JOIN band b
    WHERE s."project_short_name" = 'TCGA-LAML'
      AND s."chromosome"         = 'chr15'
      AND GREATEST(s."start_pos", b."band_start") <= LEAST(s."end_pos", b."band_end")
)
SELECT
    "case_barcode",
    ROUND(
        SUM("copy_number" * ("ov_end" - "ov_start" + 1))
        / NULLIF(SUM("ov_end" - "ov_start" + 1), 0),
        4
    ) AS "weighted_avg_copy_number"
FROM ovl
GROUP BY "case_barcode"
ORDER BY "weighted_avg_copy_number" DESC NULLS LAST;