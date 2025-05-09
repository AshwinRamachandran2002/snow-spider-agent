WITH eligible_cases AS (  -- clinical filters
    SELECT "case_barcode"
    FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),
gene_expr AS (           -- average SNORA31 counts per case, log10‑transformed
    SELECT
        "case_barcode",
        LOG(10, AVG("HTSeq__Counts") + 1) AS "log10_snora31"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_name" = 'SNORA31'
    GROUP BY "case_barcode"
),
mirna_expr AS (          -- average miRNA expression per case & miRNA
    SELECT
        "case_barcode",
        "mirna_id",
        AVG("reads_per_million_miRNA_mapped") AS "avg_mirna"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-BRCA'
    GROUP BY "case_barcode", "mirna_id"
)
SELECT
    m."mirna_id" AS microrna,
    ROUND(
        (CORR(g."log10_snora31", m."avg_mirna") * SQRT(COUNT(*) - 2))
        / SQRT(1 - POWER(CORR(g."log10_snora31", m."avg_mirna"), 2))
    , 4) AS t_statistic
FROM eligible_cases e
JOIN gene_expr    g ON e."case_barcode" = g."case_barcode"
JOIN mirna_expr   m ON e."case_barcode" = m."case_barcode"
GROUP BY m."mirna_id"
HAVING COUNT(*) > 25
   AND ABS(CORR(g."log10_snora31", m."avg_mirna")) BETWEEN 0.3 AND 1.0
ORDER BY ABS(t_statistic) DESC NULLS LAST, microrna;