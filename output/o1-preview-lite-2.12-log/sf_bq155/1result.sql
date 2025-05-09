WITH ClinicalData AS (
   SELECT c."case_barcode"
   FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL" c
   WHERE c."disease_code" = 'BRCA'
     AND (c."age_at_diagnosis" / 365.25) <= 80
     AND c."pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
),
SNORA31Expr AS (
   SELECT r."case_barcode", 
          LOG(10, AVG(r."HTSeq__Counts" + 1)) AS "SNORA31_log_expr"
   FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION" r
   WHERE r."gene_name" = 'SNORA31'
   GROUP BY r."case_barcode"
),
miRNAExpr AS (
   SELECT m."case_barcode", m."mirna_id",
          AVG(m."reads_per_million_miRNA_mapped") AS "miRNA_avg_expr"
   FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION" m
   GROUP BY m."case_barcode", m."mirna_id"
),
CombinedData AS (
   SELECT c."case_barcode", s."SNORA31_log_expr", m."mirna_id", m."miRNA_avg_expr"
   FROM ClinicalData c
   JOIN SNORA31Expr s ON c."case_barcode" = s."case_barcode"
   JOIN miRNAExpr m ON c."case_barcode" = m."case_barcode"
),
CorrelationData AS (
   SELECT "mirna_id",
          COUNT(*) AS n,
          CORR("SNORA31_log_expr", "miRNA_avg_expr") AS r
   FROM CombinedData
   GROUP BY "mirna_id"
   HAVING COUNT(*) > 25
     AND ABS(CORR("SNORA31_log_expr", "miRNA_avg_expr")) BETWEEN 0.3 AND 1.0
)
SELECT "mirna_id" AS "microRNA_ID",
       r * SQRT((n - 2) / NULLIF(1 - POWER(r, 2), 0)) AS t_statistic
FROM CorrelationData
ORDER BY t_statistic DESC NULLS LAST;