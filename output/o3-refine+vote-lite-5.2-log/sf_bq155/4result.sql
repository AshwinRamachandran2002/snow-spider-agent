WITH eligible_cases AS (
    SELECT DISTINCT 
           "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL_V1"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
),
snora_per_sample AS (
    SELECT 
        rna."sample_barcode",
        LOG(10, AVG(rna."HTSeq__Counts") + 1) AS "snora_log10"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION" rna
    JOIN eligible_cases ec
      ON rna."case_barcode" = ec."case_barcode"
    WHERE rna."project_short_name" = 'TCGA-BRCA'
      AND rna."gene_name" = 'SNORA31'
    GROUP BY rna."sample_barcode"
),
mirna_per_sample AS (
    SELECT 
        mir."sample_barcode",
        mir."mirna_id",
        AVG(mir."read_count") AS "mirna_expr"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."MIRNASEQ_EXPRESSION" mir
    JOIN eligible_cases ec
      ON mir."case_barcode" = ec."case_barcode"
    WHERE mir."project_short_name" = 'TCGA-BRCA'
    GROUP BY mir."sample_barcode", mir."mirna_id"
),
joined AS (
    SELECT 
        m."mirna_id",
        s."snora_log10",
        m."mirna_expr"
    FROM mirna_per_sample m
    JOIN snora_per_sample s
      ON m."sample_barcode" = s."sample_barcode"
)
SELECT 
    "mirna_id",
    COUNT(*) AS "n_samples",
    CORR("snora_log10","mirna_expr") AS "pearson_r",
    CORR("snora_log10","mirna_expr") * SQRT(COUNT(*) - 2)
        / SQRT(1 - POWER(CORR("snora_log10","mirna_expr"), 2)) AS "t_statistic"
FROM joined
GROUP BY "mirna_id"
HAVING COUNT(*) > 25
   AND ABS(CORR("snora_log10","mirna_expr")) BETWEEN 0.3 AND 1.0
ORDER BY ABS("t_statistic") DESC NULLS LAST, "mirna_id";