WITH cohort_patients AS (
  SELECT "case_barcode"
  FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL"
  WHERE ("age_at_diagnosis" / 365.25) <= 80
    AND "pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
    AND "project_short_name" = 'TCGA-BRCA'
),
snora31_expr AS (
  SELECT e."case_barcode", LOG(10, e."HTSeq__Counts" + 1) AS "log_SNORA31_expr"
  FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION" e
  JOIN cohort_patients c ON e."case_barcode" = c."case_barcode"
  WHERE e."gene_name" = 'SNORA31' AND e."project_short_name" = 'TCGA-BRCA'
),
mirna_expr AS (
  SELECT e."case_barcode", e."mirna_id", LOG(10, e."read_count" + 1) AS "log_miRNA_expr"
  FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION" e
  JOIN cohort_patients c ON e."case_barcode" = c."case_barcode"
  WHERE e."project_short_name" = 'TCGA-BRCA'
),
averaged_expr AS (
  SELECT
    m."mirna_id",
    AVG(s."log_SNORA31_expr") AS "avg_log_SNORA31_expr",
    AVG(m."log_miRNA_expr") AS "avg_log_miRNA_expr"
  FROM snora31_expr s
  JOIN mirna_expr m ON s."case_barcode" = m."case_barcode"
  GROUP BY m."mirna_id"
),
final_stats AS (
  SELECT
    a."mirna_id" AS "microRNA_ID",
    COUNT(*) AS n,
    CORR(s."log_SNORA31_expr", m."log_miRNA_expr") AS r,
    CORR(s."log_SNORA31_expr", m."log_miRNA_expr") * SQRT((COUNT(*) - 2) / (1 - POWER(CORR(s."log_SNORA31_expr", m."log_miRNA_expr"), 2))) AS "t_statistic"
  FROM snora31_expr s
  JOIN mirna_expr m ON s."case_barcode" = m."case_barcode"
  JOIN averaged_expr a ON m."mirna_id" = a."mirna_id"
  GROUP BY a."mirna_id"
  HAVING COUNT(*) > 25 AND ABS(CORR(s."log_SNORA31_expr", m."log_miRNA_expr")) BETWEEN 0.3 AND 1.0
)
SELECT "microRNA_ID", ROUND("t_statistic", 4) AS "t_statistic"
FROM final_stats;