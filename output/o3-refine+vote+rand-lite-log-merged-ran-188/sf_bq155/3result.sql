WITH clinical_filtered AS (
    SELECT DISTINCT
           "case_barcode"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis"   <= 80
      AND  "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),
snora31_per_sample AS (
    /* log10‑transformed (HTSeq__Counts + 1) for SNORA31 */
    SELECT
        rna."sample_barcode",
        LOG(10, AVG(rna."HTSeq__Counts") + 1) AS snora31_log10
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION" rna
           JOIN clinical_filtered cf
             ON rna."case_barcode" = cf."case_barcode"
    WHERE  rna."project_short_name" = 'TCGA-BRCA'
      AND  rna."gene_name"          = 'SNORA31'
    GROUP  BY rna."sample_barcode"
),
mirna_per_sample AS (
    /* average miRNA expression (reads_per_million_miRNA_mapped) */
    SELECT
        mirna."sample_barcode",
        mirna."mirna_id",
        AVG(mirna."reads_per_million_miRNA_mapped") AS mirna_expr
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."MIRNASEQ_EXPRESSION" mirna
           JOIN clinical_filtered cf
             ON mirna."case_barcode" = cf."case_barcode"
    WHERE  mirna."project_short_name" = 'TCGA-BRCA'
    GROUP  BY mirna."sample_barcode",
             mirna."mirna_id"
),
paired_values AS (
    /* samples with both SNORA31 and the miRNA measurements */
    SELECT
        mps."mirna_id",
        sps.snora31_log10 AS snora_val,
        mps.mirna_expr    AS mirna_val
    FROM   snora31_per_sample sps
           JOIN mirna_per_sample mps
             ON sps."sample_barcode" = mps."sample_barcode"
),
corr_stats AS (
    /* Pearson correlation and sample size for every miRNA */
    SELECT
        "mirna_id",
        COUNT(*)                           AS n_samples,
        CORR(snora_val, mirna_val)         AS pearson_r
    FROM   paired_values
    GROUP  BY "mirna_id"
)
SELECT
       "mirna_id",
       n_samples,
       pearson_r,
       pearson_r * SQRT(n_samples - 2) / SQRT(1 - POWER(pearson_r, 2)) AS t_stat
FROM   corr_stats
WHERE  n_samples > 25
  AND  ABS(pearson_r) BETWEEN 0.3 AND 1.0
ORDER  BY ABS(t_stat) DESC NULLS LAST;