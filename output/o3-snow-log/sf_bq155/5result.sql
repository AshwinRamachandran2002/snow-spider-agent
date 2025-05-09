WITH clinical_filtered AS (
    /* TCGA-BRCA cases ≤ 80 yr at diagnosis and pathologic stage I / II / IIA */
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" IS NOT NULL
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
),
snora AS (
    /* log10-transformed average SNORA31 RNA-Seq expression per sample */
    SELECT
        r."sample_barcode",
        LOG(10, AVG(r."HTSeq__Counts") + 1) AS "snora_expr"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    JOIN clinical_filtered c
      ON r."case_barcode" = c."case_barcode"
    WHERE r."gene_name" = 'SNORA31'
    GROUP BY r."sample_barcode"
),
mirna AS (
    /* average microRNA-Seq expression per microRNA per sample */
    SELECT
        m."sample_barcode",
        m."mirna_id",
        AVG(m."reads_per_million_miRNA_mapped") AS "mirna_expr"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION m
    JOIN clinical_filtered c
      ON m."case_barcode" = c."case_barcode"
    GROUP BY m."sample_barcode", m."mirna_id"
),
pairs AS (
    /* pair each sample’s SNORA31 value with each microRNA value */
    SELECT
        s."snora_expr",
        mi."mirna_id",
        mi."mirna_expr"
    FROM snora s
    JOIN mirna mi
      ON s."sample_barcode" = mi."sample_barcode"
    WHERE mi."mirna_expr" IS NOT NULL
),
stats AS (
    /* per-microRNA Pearson r and paired-sample count */
    SELECT
        "mirna_id",
        COUNT(*)                              AS "n_samples",
        CORR("snora_expr","mirna_expr")       AS "r"
    FROM pairs
    GROUP BY "mirna_id"
    HAVING COUNT(*) > 25
)
SELECT
    "mirna_id",
    "n_samples",
    "r"                                                             AS "pearson_r",
    /* t = r * sqrt((n-2)/(1-r²)) */
    "r" * SQRT( ("n_samples" - 2) / (1 - POWER("r", 2)) )           AS "t_statistic"
FROM stats
WHERE ABS("r") BETWEEN 0.3 AND 1.0
ORDER BY ABS("t_statistic") DESC NULLS LAST;