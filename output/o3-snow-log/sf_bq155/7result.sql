WITH eligible_cases AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" IS NOT NULL
      AND "age_at_diagnosis" <= 80 * 365          -- ≤ 80 years
      AND "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),

snora31_expr AS (
    SELECT
        "case_barcode",
        LOG(10, AVG("HTSeq__Counts" + 1)) AS "snora31_log_exp"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_name" = 'SNORA31'
      AND "case_barcode" IN (SELECT "case_barcode" FROM eligible_cases)
    GROUP BY "case_barcode"
),

mirna_expr AS (
    SELECT
        "case_barcode",
        "mirna_id",
        AVG("reads_per_million_miRNA_mapped") AS "mirna_exp"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "case_barcode" IN (SELECT "case_barcode" FROM eligible_cases)
    GROUP BY "case_barcode","mirna_id"
),

joined AS (
    SELECT
        m."mirna_id",
        s."snora31_log_exp",
        m."mirna_exp"
    FROM snora31_expr  s
    JOIN mirna_expr    m
      ON s."case_barcode" = m."case_barcode"
),

stats AS (
    SELECT
        "mirna_id",
        COUNT(*)                               AS "n_samples",
        CORR("snora31_log_exp","mirna_exp")     AS "r_pearson"
    FROM joined
    GROUP BY "mirna_id"
)

SELECT
    "mirna_id",
    "n_samples",
    "r_pearson",
    "r_pearson" * SQRT( ("n_samples" - 2) / (1 - POWER("r_pearson",2)) ) AS "t_statistic"
FROM stats
WHERE "n_samples" > 25
  AND ABS("r_pearson") BETWEEN 0.3 AND 1.0
ORDER BY "t_statistic" DESC NULLS LAST;