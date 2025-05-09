/*--------------------------------------------------------------------
  TCGA‑BRCA patients ≤ 80 yrs, pathologic stage I / II / IIA
  Pearson r (and corresponding t‑statistic) between:
      • log10( avg HTSeq__Counts + 1 ) for SNORA31
      • avg miRNA reads‑per‑million for each miRNA
  Keep miRNAs with >25 samples and |r| ∈ [0.3 , 1]
--------------------------------------------------------------------*/
WITH patient_filter AS (              -- eligible cases
    SELECT DISTINCT "case_barcode"
    FROM  TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL_V1"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis"  <= 80
      AND "pathologic_stage"  IN ('Stage I','Stage II','Stage IIA')
),

snora31_rna AS (                      -- log10‑transformed SNORA31 per sample
    SELECT
        "sample_barcode",
        "case_barcode",
        LOG(10, AVG("HTSeq__Counts") + 1)      AS "snora31_log"
    FROM  TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_name"          = 'SNORA31'
    GROUP BY "sample_barcode", "case_barcode"
),

mirna_exp AS (                        -- mean miRNA expression per sample/miRNA
    SELECT
        "sample_barcode",
        "mirna_id",
        AVG("reads_per_million_miRNA_mapped")  AS "mirna_expr"
    FROM  TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."MIRNASEQ_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-BRCA'
    GROUP BY "sample_barcode", "mirna_id"
),

joined AS (                           -- link RNA & miRNA within filtered cases
    SELECT
        m."mirna_id",
        r."snora31_log",
        m."mirna_expr"
    FROM  snora31_rna       r
    JOIN  patient_filter    p ON p."case_barcode" = r."case_barcode"
    JOIN  mirna_exp         m ON m."sample_barcode" = r."sample_barcode"
),

agg AS (                              -- Pearson r and sample size per miRNA
    SELECT
        "mirna_id",
        COUNT(*)                          AS n_samples,
        CORR("snora31_log","mirna_expr")  AS pearson_r
    FROM  joined
    GROUP BY "mirna_id"
    HAVING COUNT(*) > 25
       AND ABS(CORR("snora31_log","mirna_expr")) BETWEEN 0.3 AND 1.0
)

SELECT
    "mirna_id",
    n_samples,
    ROUND(pearson_r, 4)                                                    AS pearson_r,
    ROUND( pearson_r * SQRT( (n_samples - 2) / (1 - POWER(pearson_r, 2)) )
          , 4)                                                             AS t_statistic
FROM  agg
ORDER BY t_statistic DESC NULLS LAST;