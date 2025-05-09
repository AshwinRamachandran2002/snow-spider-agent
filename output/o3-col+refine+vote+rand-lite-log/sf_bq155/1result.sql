WITH elig_cases AS (   -- TCGA-BRCA cases ≤80 yrs & stage I / II / IIA
    SELECT DISTINCT "case_barcode"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis"  <= 80
      AND  "pathologic_stage"  IN ('Stage I','Stage II','Stage IIA')
),
snora AS (              -- log10-transformed mean SNORA31 RNA-Seq counts per sample
    SELECT  r."sample_barcode",
            LOG(10, AVG(r."HTSeq__Counts") + 1)  AS "log10_SNORA31"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION" r
    JOIN    elig_cases e
           ON e."case_barcode" = r."case_barcode"
    WHERE   r."gene_name" = 'SNORA31'
    GROUP BY r."sample_barcode"
),
mirna AS (              -- mean miRNA-Seq expression per (sample, miRNA)
    SELECT  m."sample_barcode",
            m."mirna_id",
            AVG(m."reads_per_million_miRNA_mapped") AS "avg_miRNA_expr"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."MIRNASEQ_EXPRESSION" m
    JOIN    elig_cases e
           ON e."case_barcode" = m."case_barcode"
    GROUP BY m."sample_barcode", m."mirna_id"
),
corr_tbl AS (           -- Pearson r & sample count for each miRNA
    SELECT  mi."mirna_id",
            COUNT(*)                                         AS n_samples,
            CORR(s."log10_SNORA31", mi."avg_miRNA_expr")     AS pearson_r
    FROM    snora s
    JOIN    mirna mi
           ON mi."sample_barcode" = s."sample_barcode"
    GROUP BY mi."mirna_id"
    HAVING  COUNT(*) > 25
       AND  ABS(CORR(s."log10_SNORA31", mi."avg_miRNA_expr")) BETWEEN 0.3 AND 1.0
)
SELECT  "mirna_id",
        n_samples,
        pearson_r,
        pearson_r * SQRT(n_samples - 2) / SQRT(1 - POWER(pearson_r, 2)) AS t_statistic
FROM    corr_tbl
ORDER BY ABS(t_statistic) DESC NULLS LAST;