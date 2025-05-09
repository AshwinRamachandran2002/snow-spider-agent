WITH eligible_cases AS (
    SELECT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "disease_code" = 'BRCA'
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),
snora31_per_sample AS (
    SELECT
        "sample_barcode",
        LOG(10, AVG("HTSeq__Counts") + 1) AS "log10_snora31"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_name" = 'SNORA31'
      AND "case_barcode" IN (SELECT "case_barcode" FROM eligible_cases)
    GROUP BY "sample_barcode"
),
mirna_per_sample AS (
    SELECT
        "sample_barcode",
        "mirna_id",
        AVG("reads_per_million_miRNA_mapped") AS "avg_mirna_rpm"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "case_barcode" IN (SELECT "case_barcode" FROM eligible_cases)
    GROUP BY "sample_barcode", "mirna_id"
),
corr_table AS (
    SELECT
        m."mirna_id" AS "microrna",
        COUNT(*)     AS "n_samples",
        CORR(s."log10_snora31", m."avg_mirna_rpm") AS "pearson_r"
    FROM mirna_per_sample m
    JOIN snora31_per_sample s
      ON m."sample_barcode" = s."sample_barcode"
    GROUP BY m."mirna_id"
    HAVING COUNT(*) > 25
       AND ABS(CORR(s."log10_snora31", m."avg_mirna_rpm")) BETWEEN 0.3 AND 1.0
)
SELECT
    "microrna",
    ROUND(
        "pearson_r" * SQRT( ("n_samples" - 2) / (1 - POWER("pearson_r", 2)) ),
        4
    ) AS "t_statistic"
FROM corr_table
ORDER BY ABS("t_statistic") DESC NULLS LAST;