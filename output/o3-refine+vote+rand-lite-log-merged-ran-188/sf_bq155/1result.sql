WITH clinic_filter AS (  -- 1. Eligible BRCA cases
    SELECT "case_barcode"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis"  <= 80
      AND  "pathologic_stage"  IN ('Stage I','Stage II','Stage IIA')
),
rna_snora31 AS (         -- 2. log10‑transformed SNORA31 RNA‑Seq expression
    SELECT  "case_barcode",
            LOG(10, AVG("HTSeq__Counts") + 1)  AS snora31_log
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"
    WHERE   "project_short_name" = 'TCGA-BRCA'
      AND   "gene_name"          = 'SNORA31'
    GROUP BY "case_barcode"
),
mirna_expr AS (          -- 3. average miRNA expression per case & miRNA
    SELECT  "case_barcode",
            "mirna_id",
            AVG("reads_per_million_miRNA_mapped") AS mirna_expr
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."MIRNASEQ_EXPRESSION"
    WHERE   "project_short_name" = 'TCGA-BRCA'
    GROUP BY "case_barcode", "mirna_id"
),
joined_data AS (         -- 4. rows with both data types and passing clinical filter
    SELECT  m."mirna_id",
            r.snora31_log,
            m.mirna_expr
    FROM    clinic_filter c
    JOIN    rna_snora31  r ON r."case_barcode" = c."case_barcode"
    JOIN    mirna_expr   m ON m."case_barcode" = c."case_barcode"
)
SELECT  mirna_id,
        n_samples,
        pearson_r,
        pearson_r * SQRT(n_samples - 2) / SQRT(1 - pearson_r * pearson_r) AS t_statistic
FROM (
        SELECT  "mirna_id"              AS mirna_id,
                COUNT(*)                 AS n_samples,
                CORR(snora31_log, mirna_expr) AS pearson_r
        FROM    joined_data
        GROUP BY "mirna_id"
     ) corr_stats
WHERE   n_samples > 25
  AND   ABS(pearson_r) BETWEEN 0.3 AND 1.0
ORDER BY ABS(pearson_r) DESC NULLS LAST;