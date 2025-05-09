WITH snora AS (
    /* per-sample average RNA-Seq counts for SNORA31 */
    SELECT
        "sample_barcode",
        AVG("HTSeq__Counts") AS "snora_counts"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_name"          = 'SNORA31'
    GROUP BY "sample_barcode"
),
mirna AS (
    /* per-sample average microRNA expression (RPM) */
    SELECT
        "sample_barcode",
        "mirna_id",
        AVG("reads_per_million_miRNA_mapped") AS "mirna_expr"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
    GROUP BY "sample_barcode", "mirna_id"
),
clin AS (
    /* BRCA cases ≤80 yrs and Stage I/II/IIA */
    SELECT DISTINCT
        "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis"  <= 80
      AND "pathologic_stage"  IN ('Stage I', 'Stage II', 'Stage IIA')
)
SELECT
    stats."mirna_id",
    stats."pearson_r",
    stats."num_samples",
    stats."pearson_r" * SQRT(stats."num_samples" - 2)
        / SQRT(1 - POWER(stats."pearson_r", 2))            AS "t_statistic"
FROM (
    /* compute Pearson r between log10(SNORA31) and miRNA expression */
    SELECT
        m."mirna_id",
        COUNT(*)                                           AS "num_samples",
        CORR(
             LOG(10, s."snora_counts" + 1),                -- log10-transform
             m."mirna_expr"
        )                                                  AS "pearson_r"
    FROM snora s
    JOIN mirna m  ON m."sample_barcode" = s."sample_barcode"
    JOIN clin  c  ON c."case_barcode"   = SUBSTR(s."sample_barcode", 1, 12)
    GROUP BY m."mirna_id"
) stats
WHERE stats."num_samples" > 25
  AND ABS(stats."pearson_r") BETWEEN 0.3 AND 1
ORDER BY ABS(stats."pearson_r") DESC NULLS LAST;