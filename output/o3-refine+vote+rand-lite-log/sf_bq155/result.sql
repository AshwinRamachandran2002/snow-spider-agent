WITH clinical_filtered AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
      AND "case_barcode" IS NOT NULL
),
samples_with_snora AS (
    SELECT DISTINCT r."sample_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    JOIN clinical_filtered c
      ON SUBSTR(r."sample_barcode", 1, 12) = c."case_barcode"
    WHERE r."gene_name" = 'SNORA31'
),
snora_expr AS (
    SELECT 
        r."sample_barcode",
        LOG(10, AVG(r."HTSeq__Counts" + 1)) AS snora_expr
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    JOIN samples_with_snora s
      ON s."sample_barcode" = r."sample_barcode"
    WHERE r."gene_name" = 'SNORA31'
    GROUP BY r."sample_barcode"
),
mirna_expr AS (
    SELECT 
        m."sample_barcode",
        m."mirna_id",
        AVG(m."reads_per_million_miRNA_mapped") AS mirna_expr
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION m
    JOIN samples_with_snora s
      ON s."sample_barcode" = m."sample_barcode"
    GROUP BY m."sample_barcode", m."mirna_id"
),
joined AS (
    SELECT 
        me."mirna_id",
        se.snora_expr,
        me.mirna_expr
    FROM mirna_expr me
    JOIN snora_expr se
      ON me."sample_barcode" = se."sample_barcode"
),
correlations AS (
    SELECT
        "mirna_id",
        COUNT(*)                     AS n_samples,
        CORR(snora_expr, mirna_expr) AS r_value
    FROM joined
    GROUP BY "mirna_id"
)
SELECT
    "mirna_id",
    n_samples,
    r_value,
    r_value * SQRT(n_samples - 2) / SQRT(1 - r_value * r_value) AS t_statistic
FROM correlations
WHERE n_samples > 25
  AND ABS(r_value) BETWEEN 0.3 AND 1.0
ORDER BY ABS(t_statistic) DESC NULLS LAST, "mirna_id";