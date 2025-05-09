WITH total_cases AS (
    SELECT
        COUNT(DISTINCT cn."case_barcode") AS total_case_count
    FROM
        "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" AS cn
    WHERE
        cn."project_short_name" = 'TCGA-BRCA'
),
overlaps AS (
    SELECT
        cn."case_barcode",
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        cn."copy_number",
        GREATEST(cb."hg38_start", cn."start_pos") AS "overlap_start",
        LEAST(cb."hg38_stop", cn."end_pos") AS "overlap_end",
        LEAST(cb."hg38_stop", cn."end_pos") - GREATEST(cb."hg38_start", cn."start_pos") AS "overlap_length"
    FROM
        "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" AS cn
    JOIN
        "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" AS cb
        ON cn."chromosome" = cb."chromosome"
            AND cn."end_pos" >= cb."hg38_start"
            AND cn."start_pos" <= cb."hg38_stop"
    WHERE
        cn."project_short_name" = 'TCGA-BRCA'
        AND cn."copy_number" IS NOT NULL
),
weighted_copy_numbers AS (
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        SUM("overlap_length" * "copy_number") AS "weighted_sum_copy_number",
        SUM("overlap_length") AS "total_overlap_length"
    FROM
        overlaps
    GROUP BY
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    HAVING
        SUM("overlap_length") > 0
),
avg_copy_numbers AS (
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        ROUND( "weighted_sum_copy_number" / "total_overlap_length" ) AS "rounded_copy_number"
    FROM
        weighted_copy_numbers
),
cnv_classification AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        CASE
            WHEN "rounded_copy_number" = 0 THEN 'homozygous_deletion'
            WHEN "rounded_copy_number" = 1 THEN 'heterozygous_deletion'
            WHEN "rounded_copy_number" = 2 THEN 'normal_diploid'
            WHEN "rounded_copy_number" = 3 THEN 'gain'
            WHEN "rounded_copy_number" >= 4 THEN 'amplification'
            ELSE 'unknown'
        END AS "cnv_type"
    FROM
        avg_copy_numbers
),
frequencies AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        COUNT(CASE WHEN "cnv_type" = 'homozygous_deletion' THEN 1 END) AS homo_del,
        COUNT(CASE WHEN "cnv_type" = 'heterozygous_deletion' THEN 1 END) AS hetero_del,
        COUNT(CASE WHEN "cnv_type" = 'normal_diploid' THEN 1 END) AS normal_diploid,
        COUNT(CASE WHEN "cnv_type" = 'gain' THEN 1 END) AS gain_cn,
        COUNT(CASE WHEN "cnv_type" = 'amplification' THEN 1 END) AS amplification,
        COUNT(DISTINCT "case_barcode") AS case_count
    FROM
        cnv_classification
    GROUP BY
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
)
SELECT
    f."cytoband_name",
    f."hg38_start",
    f."hg38_stop",
    ROUND( (f.homo_del / tc.total_case_count) * 100, 4 ) AS "homozygous_deletion_freq",
    ROUND( (f.hetero_del / tc.total_case_count) * 100, 4 ) AS "heterozygous_deletion_freq",
    ROUND( (f.normal_diploid / tc.total_case_count) * 100, 4 ) AS "normal_diploid_freq",
    ROUND( (f.gain_cn / tc.total_case_count) * 100, 4 ) AS "gain_freq",
    ROUND( (f.amplification / tc.total_case_count) * 100, 4 ) AS "amplification_freq"
FROM
    frequencies f
CROSS JOIN
    total_cases tc
ORDER BY
    f."cytoband_name";