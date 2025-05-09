/*  Pearson correlation (and t–statistic) between log10-SNORA31 RNA-Seq expression 
    and miRNA-Seq abundance in TCGA-BRCA patients  ≤80 y with Stage I / II / IIA disease. */

WITH eligible_cases AS (          --  TCGA-BRCA cases that meet the clinical criteria
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis"   <= 80
      AND "pathologic_stage"   IN ('Stage I', 'Stage II', 'Stage IIA')
),

snora AS (                        --  log10-transformed mean RNA-Seq counts for SNORA31
    SELECT
        r."sample_barcode",
        LOG(10, AVG(r."HTSeq__Counts" + 1)) AS "log10_snora31"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    WHERE r."project_short_name" = 'TCGA-BRCA'
      AND r."gene_name"          = 'SNORA31'
      AND SUBSTR(r."sample_barcode",1,12) IN (SELECT "case_barcode" FROM eligible_cases)
    GROUP BY r."sample_barcode"
),

mirna_avg AS (                    --  mean miRNA RPM values per (miRNA, sample)
    SELECT
        m."mirna_id",
        m."sample_barcode",
        AVG(m."reads_per_million_miRNA_mapped") AS "mirna_expr"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION m
    WHERE m."project_short_name" = 'TCGA-BRCA'
      AND SUBSTR(m."sample_barcode",1,12) IN (SELECT "case_barcode" FROM eligible_cases)
    GROUP BY m."mirna_id", m."sample_barcode"
),

joined AS (                       --  pair SNORA31 values with each miRNA value
    SELECT
        ma."mirna_id",
        s."log10_snora31",
        ma."mirna_expr"
    FROM snora s
    JOIN mirna_avg ma
          ON s."sample_barcode" = ma."sample_barcode"
)

SELECT
    "mirna_id",
    COUNT(*)                                       AS "n_samples",
    CORR("log10_snora31","mirna_expr")             AS "pearson_r",
    CORR("log10_snora31","mirna_expr")
        * SQRT(COUNT(*) - 2)
        / SQRT(1 - POWER(CORR("log10_snora31","mirna_expr"),2))  AS "t_statistic"
FROM joined
GROUP BY "mirna_id"
HAVING COUNT(*) > 25
   AND ABS(CORR("log10_snora31","mirna_expr")) BETWEEN 0.3 AND 1.0
ORDER BY ABS("t_statistic") DESC NULLS LAST;