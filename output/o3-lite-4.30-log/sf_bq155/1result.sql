WITH eligible_cases AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),
snora_expr AS (
    SELECT r."case_barcode",
           AVG( LOG(10, r."HTSeq__Counts" + 1) ) AS "log10_snora31"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    JOIN eligible_cases e
      ON r."case_barcode" = e."case_barcode"
    WHERE r."gene_name" = 'SNORA31'
    GROUP BY r."case_barcode"
),
mirna_expr AS (
    SELECT m."case_barcode",
           m."mirna_id",
           AVG(m."reads_per_million_miRNA_mapped") AS "avg_mirna_rpm"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION m
    JOIN eligible_cases e
      ON m."case_barcode" = e."case_barcode"
    GROUP BY m."case_barcode", m."mirna_id"
),
corr_table AS (
    SELECT me."mirna_id",
           CORR(me."avg_mirna_rpm", se."log10_snora31") AS "pearson_r",
           COUNT(*) AS "n_samples"
    FROM mirna_expr me
    JOIN snora_expr se
      ON me."case_barcode" = se."case_barcode"
    GROUP BY me."mirna_id"
),
qualified AS (
    SELECT "mirna_id",
           ("pearson_r" * SQRT("n_samples" - 2)) / SQRT(1 - POWER("pearson_r", 2)) AS "t_statistic"
    FROM corr_table
    WHERE ABS("pearson_r") BETWEEN 0.3 AND 1.0
      AND "n_samples" > 25
)
SELECT "mirna_id" AS microrna,
       ROUND("t_statistic", 4) AS t_statistic
FROM qualified
ORDER BY ABS("t_statistic") DESC NULLS LAST;