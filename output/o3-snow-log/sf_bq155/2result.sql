WITH patients AS (      -- TCGA-BRCA cases meeting clinical criteria
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),
samples AS (           -- RNA-seq sample barcodes for those cases
    SELECT DISTINCT r."sample_barcode",
           r."case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    JOIN patients p
      ON r."case_barcode" = p."case_barcode"
),
snora_expr AS (        -- log10(AVG(Counts)+1) for SNORA31 per sample
    SELECT s."sample_barcode",
           LN( AVG(r."HTSeq__Counts") + 1 ) / LN(10)  AS "snora_expr"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    JOIN samples s
      ON r."sample_barcode" = s."sample_barcode"
    WHERE r."gene_name" = 'SNORA31'
    GROUP BY s."sample_barcode"
),
mirna_expr AS (        -- average miRNA expression per sample / miRNA
    SELECT m."sample_barcode",
           m."mirna_id",
           AVG(m."reads_per_million_miRNA_mapped") AS "mirna_expr"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION m
    JOIN samples s
      ON m."sample_barcode" = s."sample_barcode"
    GROUP BY m."sample_barcode", m."mirna_id"
),
paired AS (            -- combine SNORA31 with each miRNA
    SELECT e."mirna_id",
           n."snora_expr",
           e."mirna_expr"
    FROM mirna_expr e
    JOIN snora_expr n
      ON e."sample_barcode" = n."sample_barcode"
),
corr_stats AS (        -- Pearson r and sample size
    SELECT
        "mirna_id",
        COUNT(*)                        AS "n",
        CORR("mirna_expr", "snora_expr") AS "r"
    FROM paired
    GROUP BY "mirna_id"
    HAVING "n" > 25
       AND ABS("r") BETWEEN 0.3 AND 1.0
)
SELECT
    "mirna_id",
    "n",
    "r",
    ("r" * SQRT("n" - 2) / SQRT(1 - "r" * "r")) AS "t_statistic"
FROM corr_stats
ORDER BY ABS("t_statistic") DESC NULLS LAST;