WITH cohort_patients AS (
    SELECT DISTINCT "case_barcode"
    FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL_V1_1"
    WHERE "disease_code" = 'BRCA'
      AND TRY_TO_NUMBER("age_at_diagnosis") <= 80
      AND "pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
      AND "case_barcode" IS NOT NULL
),
snora31_expr AS (
    SELECT "case_barcode",
           LOG(10, "HTSeq__FPKM" + 1) AS "snora31_log_expr"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
    WHERE "gene_name" = 'SNORA31'
      AND "case_barcode" IS NOT NULL
),
miRNA_expr AS (
    SELECT "case_barcode",
           "mirna_id",
           LOG(10, "reads_per_million_miRNA_mapped" + 1) AS "miRNA_log_expr"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION"
    WHERE "case_barcode" IS NOT NULL
          AND "reads_per_million_miRNA_mapped" IS NOT NULL
),
miRNA_cohort_expr AS (
    SELECT m."case_barcode",
           m."mirna_id",
           m."miRNA_log_expr"
    FROM miRNA_expr m
    INNER JOIN cohort_patients c ON m."case_barcode" = c."case_barcode"
    WHERE m."miRNA_log_expr" IS NOT NULL
),
data AS (
    SELECT m."case_barcode",
           m."mirna_id",
           m."miRNA_log_expr",
           s."snora31_log_expr"
    FROM miRNA_cohort_expr m
    INNER JOIN snora31_expr s ON m."case_barcode" = s."case_barcode"
    WHERE s."snora31_log_expr" IS NOT NULL
),
stats AS (
    SELECT
        "mirna_id",
        COUNT(*) AS n,
        SUM("snora31_log_expr") AS sum_x,
        SUM("miRNA_log_expr") AS sum_y,
        SUM("snora31_log_expr" * "snora31_log_expr") AS sum_xx,
        SUM("miRNA_log_expr" * "miRNA_log_expr") AS sum_yy,
        SUM("snora31_log_expr" * "miRNA_log_expr") AS sum_xy
    FROM data
    GROUP BY "mirna_id"
),
correlations AS (
    SELECT
        "mirna_id",
        n,
        sum_x,
        sum_y,
        sum_xx,
        sum_yy,
        sum_xy,
        (n * sum_xy - sum_x * sum_y) /
        NULLIF(SQRT( (n * sum_xx - sum_x * sum_x) * (n * sum_yy - sum_y * sum_y) ), 0) AS r
    FROM stats
    WHERE n > 25
)
SELECT
    "mirna_id" AS "miRNA_ID",
    ROUND(r, 4) AS "Pearson_Correlation",
    ROUND(r * SQRT( (n - 2) / NULLIF(1 - r * r, 0) ), 4) AS "t_statistic",
    n AS "Sample_Size"
FROM correlations
WHERE ABS(r) >= 0.3 AND ABS(r) < 1.0
  AND r IS NOT NULL
ORDER BY "miRNA_ID";