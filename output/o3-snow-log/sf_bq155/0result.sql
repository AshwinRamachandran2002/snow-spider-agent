WITH eligible_cases AS (   -- TCGA-BRCA patients meeting clinical filters
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),
snora_per_case AS (        -- mean SNORA31 RNA-Seq counts per case
    SELECT 
        ec."case_barcode",
        AVG(r."HTSeq__Counts") AS "avg_counts"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    JOIN eligible_cases ec
          ON ec."case_barcode" = r."case_barcode"
    WHERE r."gene_name" = 'SNORA31'
    GROUP BY ec."case_barcode"
),
snora_log AS (             -- log10-transformed SNORA31 expression
    SELECT 
        "case_barcode",
        LOG(10, "avg_counts" + 1) AS "snora_log_expr"
    FROM snora_per_case
),
mirna_per_case AS (        -- mean miRNA expression per miRNA / case
    SELECT 
        ec."case_barcode",
        r."mirna_id",
        AVG(r."reads_per_million_miRNA_mapped") AS "avg_mirna_expr"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION r
    JOIN eligible_cases ec
          ON ec."case_barcode" = r."case_barcode"
    GROUP BY ec."case_barcode", r."mirna_id"
),
paired_data AS (           -- pair SNORA31 and miRNA data
    SELECT 
        m."mirna_id",
        s."snora_log_expr",
        m."avg_mirna_expr"
    FROM mirna_per_case m
    JOIN snora_log s
          ON s."case_barcode" = m."case_barcode"
),
miRNA_stats AS (           -- Pearson r per miRNA
    SELECT
        "mirna_id",
        COUNT(*) AS "n_samples",
        CORR("snora_log_expr","avg_mirna_expr") AS "r"
    FROM paired_data
    GROUP BY "mirna_id"
    HAVING COUNT(*) > 25
       AND ABS(CORR("snora_log_expr","avg_mirna_expr")) BETWEEN 0.3 AND 1.0
)
SELECT
    "mirna_id",
    "n_samples",
    "r",
    "r" * SQRT("n_samples" - 2) / SQRT(1 - "r" * "r") AS "t_statistic"
FROM miRNA_stats
ORDER BY ABS("r") DESC NULLS LAST;