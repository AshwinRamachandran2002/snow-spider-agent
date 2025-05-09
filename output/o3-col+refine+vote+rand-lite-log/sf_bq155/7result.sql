WITH eligible_cases AS (   -- BRCA cases that satisfy the clinical filters
    SELECT DISTINCT "case_barcode"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL_V1"
    WHERE  "project_short_name"  = 'TCGA-BRCA'
      AND  "age_at_diagnosis"   IS NOT NULL
      AND  "age_at_diagnosis"  <= 80
      AND  "pathologic_stage"   IN ('Stage I','Stage II','Stage IIA')
),
eligible_samples AS (      -- sample barcodes belonging to those cases
    SELECT DISTINCT "sample_barcode"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
    WHERE  "case_barcode" IN (SELECT "case_barcode" FROM eligible_cases)
),
snora31_rna AS (           -- log10-transformed SNORA31 RNA expression per sample
    SELECT
        "sample_barcode",
        LOG(10, AVG("HTSeq__Counts" + 1)) AS "log10_rna"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
    WHERE  "gene_name"      = 'SNORA31'
      AND  "sample_barcode" IN (SELECT "sample_barcode" FROM eligible_samples)
    GROUP BY "sample_barcode"
),
mirna_expr AS (            -- log10-transformed miRNA expression per sample & miRNA
    SELECT
        "sample_barcode",
        "mirna_id",
        LOG(10, AVG("reads_per_million_miRNA_mapped") + 1) AS "log10_mirna"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION"
    WHERE  "sample_barcode" IN (SELECT "sample_barcode" FROM eligible_samples)
    GROUP BY "sample_barcode", "mirna_id"
),
joined AS (                -- pair SNORA31 RNA with each miRNA for the same sample
    SELECT
        m."mirna_id",
        m."log10_mirna",
        r."log10_rna"
    FROM   mirna_expr  m
    JOIN   snora31_rna r
           ON m."sample_barcode" = r."sample_barcode"
),
correlations AS (          -- Pearson r and sample count for every miRNA
    SELECT
        "mirna_id",
        CORR("log10_rna","log10_mirna") AS "pearson_r",
        COUNT(*)                       AS "n_samples"
    FROM   joined
    GROUP BY "mirna_id"
    HAVING COUNT(*) > 25
       AND ABS(CORR("log10_rna","log10_mirna")) BETWEEN 0.3 AND 1.0
)
SELECT
    "mirna_id",
    ROUND("pearson_r", 4)                                           AS "pearson_r",
    "n_samples",
    ROUND("pearson_r" * SQRT( ("n_samples" - 2) /
                              (1 - POWER("pearson_r", 2)) ), 4)     AS "t_statistic"
FROM   correlations
ORDER BY ABS("pearson_r") DESC NULLS LAST;