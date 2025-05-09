WITH eligible_cases AS (
    SELECT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" <= 80
      AND (
           "pathologic_stage" ILIKE '%Stage I%'   -- captures Stage I
        OR "pathologic_stage" ILIKE '%Stage II%'  -- captures Stage II and Stage IIA
          )
),
snora31_rna AS (
    SELECT
        "case_barcode",
        AVG("HTSeq__Counts") AS "avg_snora31_counts"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_name" = 'SNORA31'
    GROUP BY "case_barcode"
),
mirna_avg AS (
    SELECT
        "case_barcode",
        "mirna_id",
        AVG("read_count") AS "avg_mirna_read"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION
    WHERE "project_short_name" = 'TCGA-BRCA'
    GROUP BY "case_barcode", "mirna_id"
),
stats AS (
    SELECT
        m."mirna_id",
        CORR(
            LOG(10, r."avg_snora31_counts" + 1),
            LOG(10, m."avg_mirna_read"    + 1)
        )            AS "pearson_r",
        COUNT(*)      AS "n_samples"
    FROM snora31_rna r
    JOIN mirna_avg      m ON r."case_barcode" = m."case_barcode"
    JOIN eligible_cases e ON r."case_barcode" = e."case_barcode"
    GROUP BY m."mirna_id"
)
SELECT
    "mirna_id",
    "pearson_r",
    "n_samples",
    ("pearson_r" * SQRT("n_samples" - 2)) / SQRT(1 - POWER("pearson_r", 2)) AS "t_statistic"
FROM stats
WHERE "n_samples" > 25
  AND ABS("pearson_r") BETWEEN 0.3 AND 1.0
ORDER BY ABS("t_statistic") DESC NULLS LAST;