/*  Pearson r  &   t-statistic between SNORA31 log10 RNA-seq expression   
    and each miRNA RPM in TCGA-BRCA samples that satisfy:
        – age_at_diagnosis ≤ 80 yrs
        – pathologic_stage  LIKE  'Stage I%'  OR  'Stage II%'
*/

WITH cohort AS (          -- TCGA-BRCA samples meeting the clinical filters
    SELECT DISTINCT c."case_barcode"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL_V1  c
    WHERE  c."project_short_name" = 'TCGA-BRCA'
      AND  c."age_at_diagnosis" IS NOT NULL
      AND  c."age_at_diagnosis" / 365.25 <= 80          -- years
      AND ( c."pathologic_stage" ILIKE 'Stage I%'        -- Stage I / IA …
            OR c."pathologic_stage" ILIKE 'Stage II%' )  -- Stage II / IIA …
),
snora31 AS (             -- log10-transformed SNORA31 RNA-seq per sample
    SELECT  r."sample_barcode",
            LOG(10, AVG(r."HTSeq__Counts" + 1)) AS "snora31_log10"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION  r
    WHERE   r."gene_name" = 'SNORA31'
      AND   r."case_barcode" IN (SELECT "case_barcode" FROM cohort)
    GROUP BY r."sample_barcode"
),
mirna AS (                -- average miRNA RPM per sample & miRNA
    SELECT  m."mirna_id",
            m."sample_barcode",
            AVG(m."reads_per_million_miRNA_mapped") AS "mirna_avg_rpm"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION  m
    WHERE   m."case_barcode" IN (SELECT "case_barcode" FROM cohort)
    GROUP BY m."mirna_id", m."sample_barcode"
),
corrs AS (                -- Pearson r for every miRNA vs SNORA31
    SELECT  mi."mirna_id",
            COUNT(*)                                   AS "n_samples",
            CORR(mi."mirna_avg_rpm", sn."snora31_log10") AS "pearson_r"
    FROM    mirna mi
    JOIN    snora31 sn
           ON sn."sample_barcode" = mi."sample_barcode"
    GROUP BY mi."mirna_id"
    HAVING  COUNT(*) > 25
       AND  ABS(CORR(mi."mirna_avg_rpm", sn."snora31_log10")) BETWEEN 0.3 AND 1
)
SELECT  "mirna_id",
        "n_samples",
        "pearson_r",
        /*  t-statistic:  r * sqrt(n-2) / sqrt(1-r²)  */
        ("pearson_r" * SQRT("n_samples" - 2)
         / SQRT(1 - "pearson_r" * "pearson_r"))     AS "t_statistic"
FROM    corrs
ORDER BY ABS("t_statistic") DESC NULLS LAST;