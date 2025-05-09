WITH cytoband AS (
    SELECT "hg38_start", "hg38_stop"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
    WHERE "chromosome" = 'chr15' AND "cytoband_name" = '15q11'
),
segments AS (
    SELECT cnseg."case_barcode",
           GREATEST(cyt."hg38_start", cnseg."start_pos") AS overlap_start,
           LEAST(cyt."hg38_stop", cnseg."end_pos") AS overlap_end,
           cnseg."segment_mean"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14" cnseg
    CROSS JOIN cytoband cyt
    WHERE cnseg."project_short_name" = 'TCGA-LAML'
      AND cnseg."chromosome" = '15'
      AND cnseg."start_pos" <= cyt."hg38_stop"
      AND cnseg."end_pos" >= cyt."hg38_start"
),
overlaps AS (
    SELECT "case_barcode",
           (overlap_end - overlap_start) AS overlap_length,
           "segment_mean"
    FROM segments
)
SELECT "case_barcode"
FROM (
    SELECT "case_barcode",
           ROUND(SUM(overlap_length * "segment_mean") / SUM(overlap_length), 4) AS weighted_average_cn
        FROM overlaps
        GROUP BY "case_barcode"
        ORDER BY weighted_average_cn DESC NULLS LAST
        LIMIT 1
) sub;