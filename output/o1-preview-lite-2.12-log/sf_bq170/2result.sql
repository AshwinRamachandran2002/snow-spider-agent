WITH total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS total_cases
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
cnv_data AS (
    SELECT
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        CASE
            WHEN cn."segment_mean" <= -1 THEN 'homozygous_deletion_freq'
            WHEN cn."segment_mean" > -1 AND cn."segment_mean" <= -0.5 THEN 'heterozygous_deletion_freq'
            WHEN cn."segment_mean" > -0.5 AND cn."segment_mean" < 0.5 THEN 'normal_diploid_freq'
            WHEN cn."segment_mean" >= 0.5 AND cn."segment_mean" < 1 THEN 'gain_freq'
            WHEN cn."segment_mean" >= 1 THEN 'amplification_freq'
            ELSE 'unknown_freq'
        END AS CNV_Type,
        cn."case_barcode"
    FROM
        "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14" cn
        JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" cb
            ON cn."chromosome" = REPLACE(cb."chromosome", 'chr', '')
           AND cn."end_pos" >= cb."hg38_start"
           AND cn."start_pos" <= cb."hg38_stop"
    WHERE
        cn."project_short_name" = 'TCGA-BRCA'
),
cnv_counts AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        CNV_Type,
        COUNT(DISTINCT "case_barcode") AS case_count
    FROM cnv_data
    GROUP BY "cytoband_name", "hg38_start", "hg38_stop", CNV_Type
),
cnv_pivot AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        COALESCE(MAX(CASE WHEN CNV_Type = 'homozygous_deletion_freq' THEN case_count END), 0) AS homozygous_deletion_count,
        COALESCE(MAX(CASE WHEN CNV_Type = 'heterozygous_deletion_freq' THEN case_count END), 0) AS heterozygous_deletion_count,
        COALESCE(MAX(CASE WHEN CNV_Type = 'normal_diploid_freq' THEN case_count END), 0) AS normal_diploid_count,
        COALESCE(MAX(CASE WHEN CNV_Type = 'gain_freq' THEN case_count END), 0) AS gain_count,
        COALESCE(MAX(CASE WHEN CNV_Type = 'amplification_freq' THEN case_count END), 0) AS amplification_count
    FROM cnv_counts
    GROUP BY "cytoband_name", "hg38_start", "hg38_stop"
)
SELECT
    cp."cytoband_name",
    cp."hg38_start",
    cp."hg38_stop",
    ROUND(cp.homozygous_deletion_count * 100.0 / total_cases.total_cases, 2) AS homozygous_deletion_freq,
    ROUND(cp.heterozygous_deletion_count * 100.0 / total_cases.total_cases, 2) AS heterozygous_deletion_freq,
    ROUND(cp.normal_diploid_count * 100.0 / total_cases.total_cases, 2) AS normal_diploid_freq,
    ROUND(cp.gain_count * 100.0 / total_cases.total_cases, 2) AS gain_freq,
    ROUND(cp.amplification_count * 100.0 / total_cases.total_cases, 2) AS amplification_freq
FROM
    cnv_pivot cp, total_cases
ORDER BY cp."cytoband_name";