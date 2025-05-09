WITH filtered_cases AS (   -- TCGA-BRCA cases meeting clinical criteria
    SELECT DISTINCT "case_barcode"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis"  <= 80
      AND  "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),
gene_expr AS (             -- log10-transformed mean HTSeq counts (+1) for SNORA31 per sample
    SELECT  "sample_barcode",
            LOG(10, AVG("HTSeq__Counts") + 1)  AS gene_log
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE   "gene_name" = 'SNORA31'
      AND   "case_barcode" IN (SELECT "case_barcode" FROM filtered_cases)
    GROUP BY "sample_barcode"
),
mirna_expr AS (            -- mean miRNA expression per sample / miRNA
    SELECT  "sample_barcode",
            "mirna_id",
            AVG("reads_per_million_miRNA_mapped") AS mirna_expr
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION
    WHERE   "case_barcode" IN (SELECT "case_barcode" FROM filtered_cases)
    GROUP BY "sample_barcode", "mirna_id"
),
combined AS (              -- paired gene / miRNA values
    SELECT  m."mirna_id"          AS mirna_id,
            g.gene_log            AS gene_log,
            m.mirna_expr          AS mirna_expr
    FROM    mirna_expr  m
    JOIN    gene_expr   g
           ON g."sample_barcode" = m."sample_barcode"
)
SELECT
       mirna_id,
       COUNT(*)                                    AS sample_count,
       CORR(gene_log, mirna_expr)                 AS pearson_r,
       CORR(gene_log, mirna_expr) *
       SQRT(COUNT(*) - 2) /
       SQRT(1 - POWER(CORR(gene_log, mirna_expr), 2))  AS t_statistic
FROM   combined
GROUP  BY mirna_id
HAVING COUNT(*) > 25
   AND ABS(CORR(gene_log, mirna_expr)) BETWEEN 0.3 AND 1.0
ORDER BY ABS(t_statistic) DESC NULLS LAST;