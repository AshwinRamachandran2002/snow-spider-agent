WITH cohort_cases AS (  -- TCGA‑BRCA cases ≤ 80 yrs & Stage I / II / IIA
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL_V1
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis"  <= 80
      AND "pathologic_stage"  IN ('Stage I','Stage II','Stage IIA')
),

-- log10‑transformed mean RNA‑Seq counts for SNORA31 per sample
snora_log AS (
    SELECT  r."sample_barcode",
            LN( AVG(r."HTSeq__Counts") + 1 ) / LN(10)  AS "snora_log10"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    WHERE   r."project_short_name" = 'TCGA-BRCA'
      AND   r."gene_name"          = 'SNORA31'
      AND   r."case_barcode" IN (SELECT "case_barcode" FROM cohort_cases)
    GROUP BY r."sample_barcode"
),

-- mean miRNA RPM per sample & miRNA
mirna_avg AS (
    SELECT  m."sample_barcode",
            m."mirna_id",
            AVG(m."reads_per_million_miRNA_mapped") AS "mirna_avg_rpm"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION m
    WHERE   m."project_short_name" = 'TCGA-BRCA'
      AND   m."case_barcode" IN (SELECT "case_barcode" FROM cohort_cases)
    GROUP BY m."sample_barcode", m."mirna_id"
)

SELECT  ma."mirna_id",
        COUNT(*)                                         AS "n_samples",
        CORR(sl."snora_log10", ma."mirna_avg_rpm")       AS "pearson_r",
        CORR(sl."snora_log10", ma."mirna_avg_rpm")
          * SQRT(COUNT(*) - 2)
          / SQRT(1 - POWER(CORR(sl."snora_log10", ma."mirna_avg_rpm"), 2))
                                                       AS "t_statistic"
FROM        snora_log  sl
JOIN        mirna_avg  ma
       ON   sl."sample_barcode" = ma."sample_barcode"
GROUP BY    ma."mirna_id"
HAVING      COUNT(*) > 25
       AND  ABS(CORR(sl."snora_log10", ma."mirna_avg_rpm")) BETWEEN 0.3 AND 1.0
ORDER BY    ABS(CORR(sl."snora_log10", ma."mirna_avg_rpm")) DESC NULLS LAST;