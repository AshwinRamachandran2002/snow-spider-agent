WITH cytoband AS (
    SELECT "hg38_start" AS cytoband_start, "hg38_stop" AS cytoband_end
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15' AND "cytoband_name" = '15q11'
),
laml_cases AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.CLINICAL_GDC_2019_06
    WHERE "project_short_name" = 'TCGA-LAML'
),
segments AS (
    SELECT
        s."case_barcode",
        GREATEST(s."start_pos", c.cytoband_start) AS overlap_start,
        LEAST(s."end_pos", c.cytoband_end) AS overlap_end,
        s."num_probes",
        s."segment_mean",
        (LEAST(s."end_pos", c.cytoband_end) - GREATEST(s."start_pos", c.cytoband_start) + 1) AS overlap_length,
        s."end_pos" - s."start_pos" + 1 AS segment_length,
        ((LEAST(s."end_pos", c.cytoband_end) - GREATEST(s."start_pos", c.cytoband_start) + 1) / NULLIF(s."end_pos" - s."start_pos" + 1, 0)) * s."num_probes" AS overlap_num_probes,
        s."segment_mean" * (((LEAST(s."end_pos", c.cytoband_end) - GREATEST(s."start_pos", c.cytoband_start) + 1) / NULLIF(s."end_pos" - s."start_pos" + 1, 0)) * s."num_probes") AS weighted_mean
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02 s
    CROSS JOIN cytoband c
    WHERE s."chromosome" = '15'
      AND s."start_pos" <= c.cytoband_end
      AND s."end_pos" >= c.cytoband_start
      AND s."case_barcode" IN (SELECT "case_barcode" FROM laml_cases)
),
case_weighted_mean AS (
    SELECT
        "case_barcode",
        ROUND(SUM(weighted_mean) / NULLIF(SUM(overlap_num_probes), 0), 4) AS weighted_average
    FROM segments
    GROUP BY "case_barcode"
),
max_case AS (
    SELECT "case_barcode"
    FROM case_weighted_mean
    ORDER BY weighted_average DESC NULLS LAST
    LIMIT 1
)
SELECT "case_barcode"
FROM max_case