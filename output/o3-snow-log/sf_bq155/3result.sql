WITH clin AS (   -- TCGA-BRCA cases matching the clinical filters
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" IS NOT NULL
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
), 
rna AS (        -- log10-transformed mean RNA-Seq counts for SNORA31
    SELECT 
        "case_barcode",
        LOG(10, AVG("HTSeq__Counts" + 1)) AS rna_expr
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_name" = 'SNORA31'
    GROUP BY "case_barcode"
), 
mirna AS (      -- mean miRNA-Seq expression for every miRNA
    SELECT 
        "case_barcode",
        "mirna_id",
        AVG("reads_per_million_miRNA_mapped") AS mirna_expr
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
    GROUP BY "case_barcode", "mirna_id"
), 
paired AS (     -- per-case RNA/miRNA pairs after clinical filtering
    SELECT 
        m."mirna_id",
        r.rna_expr,
        m.mirna_expr
    FROM clin  c
    JOIN rna   r ON r."case_barcode" = c."case_barcode"
    JOIN mirna m ON m."case_barcode" = c."case_barcode"
), 
agg AS (        -- correlation statistics for each miRNA
    SELECT
        "mirna_id",
        COUNT(*)                           AS n_samples,
        CORR(rna_expr, mirna_expr)         AS pearson_r
    FROM paired
    GROUP BY "mirna_id"
    HAVING COUNT(*) > 25
       AND ABS(CORR(rna_expr, mirna_expr)) BETWEEN 0.3 AND 1.0
)
SELECT
    "mirna_id",
    n_samples,
    pearson_r,
    pearson_r * SQRT( (n_samples - 2) / (1 - pearson_r * pearson_r) ) AS t_statistic
FROM agg
ORDER BY ABS(t_statistic) DESC NULLS LAST;