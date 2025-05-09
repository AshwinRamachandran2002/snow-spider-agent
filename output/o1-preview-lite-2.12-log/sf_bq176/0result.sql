WITH cytoband AS (
    SELECT
        MIN("hg38_start") AS q11_start,
        MAX("hg38_stop") AS q11_end
    FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
    WHERE REPLACE("chromosome", 'chr', '') = '15' AND "cytoband_name" LIKE '15q11%'
),
segments AS (
    SELECT
        seg."case_barcode",
        seg."segment_mean",
        GREATEST(0, LEAST(seg."end_pos", cyt.q11_end) - GREATEST(seg."start_pos", cyt.q11_start)) AS overlap_length
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02" seg
    CROSS JOIN cytoband cyt
    WHERE
        seg."project_short_name" = 'TCGA-LAML'
        AND seg."chromosome" = '15'
        AND seg."start_pos" <= cyt.q11_end
        AND seg."end_pos" >= cyt.q11_start
),
weighted_avg AS (
    SELECT
        "case_barcode",
        ROUND(SUM("segment_mean" * overlap_length) / NULLIF(SUM(overlap_length), 0), 4) AS weighted_avg_segment_mean
    FROM segments
    WHERE overlap_length > 0
    GROUP BY "case_barcode"
)
SELECT "case_barcode"
FROM weighted_avg
ORDER BY weighted_avg_segment_mean DESC NULLS LAST
LIMIT 1;