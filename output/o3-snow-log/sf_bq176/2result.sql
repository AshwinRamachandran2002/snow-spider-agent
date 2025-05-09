/* 1) find genomic span for cytoband 15q11
   2) intersect TCGA-LAML allelic copy-number segments with that span
   3) compute the length-weighted average copy number per case
   4) keep the case(s) that reach the overall maximum value            */
WITH band AS (           /* genomic co-ordinates of 15q11 (hg38) */
    SELECT
        "hg38_start"  AS band_start,
        "hg38_stop"   AS band_end
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" = '15q11'
),
segments AS (            /* LAML segments on chr15 with copy-number values */
    SELECT
        s."case_barcode",
        s."start_pos",
        s."end_pos",
        s."copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    WHERE s."project_short_name" = 'TCGA-LAML'
      AND s."chromosome" = 'chr15'
      AND s."copy_number" IS NOT NULL
),
overlaps AS (            /* intersection length of segment with the band */
    SELECT
        seg."case_barcode",
        (LEAST(seg."end_pos",  band.band_end) -
         GREATEST(seg."start_pos", band.band_start) + 1) AS ov_len,
        seg."copy_number"
    FROM segments seg
    CROSS JOIN band
    WHERE seg."end_pos"   >= band.band_start
      AND seg."start_pos" <= band.band_end
)
SELECT
    "case_barcode",
    ROUND(SUM(ov_len * "copy_number") / SUM(ov_len), 4) AS weighted_avg_copy_number
FROM overlaps
GROUP BY "case_barcode"
QUALIFY weighted_avg_copy_number = MAX(weighted_avg_copy_number) OVER ()
ORDER BY weighted_avg_copy_number DESC NULLS LAST;