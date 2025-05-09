/*  t‑statistics for correlations between SNORA31 (log10(HTSeq__Counts+1))
    and each miRNA’s mean read‑count, in TCGA‑BRCA samples that meet:

    • age_at_diagnosis ≤ 80 yrs
    • pathologic_stage  ∈ {Stage I, Stage II, Stage IIA}
    • >25 paired samples
    • |Pearson r| between 0.3 and 1.0                                        */

WITH eligible_cases AS (             -- patients that satisfy the clinical filters
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL_V1"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" IS NOT NULL
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),

gene_expr AS (                       -- log10‑transformed mean SNORA31 counts
    SELECT
        "case_barcode",
        "sample_barcode",
        LOG(10, AVG("HTSeq__Counts") + 1) AS gene_expr          -- LOG(base, value)
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_name" = 'SNORA31'
    GROUP BY "case_barcode","sample_barcode"
),

mirna_expr AS (                      -- mean miRNA read‑counts
    SELECT
        "case_barcode",
        "sample_barcode",
        "mirna_id",
        AVG("read_count") AS mirna_expr
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."MIRNASEQ_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-BRCA'
    GROUP BY "case_barcode","sample_barcode","mirna_id"
),

joined AS (                          -- paired SNORA31 and miRNA expression rows
    SELECT
        m."mirna_id",
        g.gene_expr,
        m.mirna_expr
    FROM mirna_expr m
    JOIN gene_expr  g  USING ("case_barcode","sample_barcode")
    JOIN eligible_cases ec USING ("case_barcode")
)

SELECT
    "mirna_id",
    n_samples,
    r                                AS pearson_r,
    r * SQRT(n_samples - 2) / SQRT(1 - r * r) AS t_statistic
FROM (
    SELECT
        "mirna_id",
        COUNT(*)                    AS n_samples,
        CORR(gene_expr, mirna_expr) AS r
    FROM joined
    GROUP BY "mirna_id"
) stats
WHERE n_samples > 25
  AND ABS(r) BETWEEN 0.3 AND 1.0
ORDER BY ABS(t_statistic) DESC NULLS LAST, "mirna_id";