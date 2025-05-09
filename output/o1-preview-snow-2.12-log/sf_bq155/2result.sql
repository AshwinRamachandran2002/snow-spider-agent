WITH patients AS (
    SELECT DISTINCT "case_barcode"
    FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL"
    WHERE "project_short_name" = 'TCGA-BRCA'
        AND "age_at_diagnosis" <= 80
        AND "pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
), 
snora31_expr AS (
    SELECT "case_barcode", LOG(10, AVG("HTSeq__Counts") + 1) AS "SNORA31_expr"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
    WHERE "gene_name" = 'SNORA31'
    GROUP BY "case_barcode"
), 
mirna_expr AS (
    SELECT "case_barcode", "mirna_id", AVG("reads_per_million_miRNA_mapped") AS "miRNA_expr"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION"
    GROUP BY "case_barcode", "mirna_id"
), 
combined_data AS (
    SELECT m."mirna_id", s."case_barcode", s."SNORA31_expr", m."miRNA_expr"
    FROM patients p
    JOIN snora31_expr s ON p."case_barcode" = s."case_barcode"
    JOIN mirna_expr m ON s."case_barcode" = m."case_barcode"
)
SELECT 
  "mirna_id" AS microRNA_ID,
  ROUND((r * SQRT(n - 2)) / SQRT(1 - POWER(r, 2)), 4) AS t_statistic
FROM (
    SELECT 
        "mirna_id",
        COUNT(*) AS n,
        CORR("SNORA31_expr", "miRNA_expr") AS r
    FROM combined_data
    GROUP BY "mirna_id"
    HAVING COUNT(*) > 25 AND ABS(CORR("SNORA31_expr", "miRNA_expr")) BETWEEN 0.3 AND 1.0
) sub
ORDER BY t_statistic DESC NULLS LAST;