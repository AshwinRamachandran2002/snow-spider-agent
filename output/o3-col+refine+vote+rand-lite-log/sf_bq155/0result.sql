WITH cohort_cases AS (   -- BRCA cases age ≤80 yrs and stage I / II / IIA
    SELECT DISTINCT "case_barcode"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis" IS NOT NULL
      AND  ("age_at_diagnosis" / 365.25) <= 80
      AND ( UPPER("pathologic_stage") LIKE '%STAGE I%'   -- covers I, IA, IB …
            OR UPPER("pathologic_stage") LIKE '%STAGE II%' )  -- covers II, IIA, IIB …
),
-- map samples ↔ cases using the SNORA31 rows (RNA-Seq table contains both IDs)
sample_case AS (
    SELECT DISTINCT "sample_barcode",
           "case_barcode"
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"
    WHERE  "gene_name" = 'SNORA31'
),
cohort_samples AS (      -- samples belonging to the cohort cases
    SELECT sc."sample_barcode"
    FROM   sample_case sc
    JOIN   cohort_cases cc ON sc."case_barcode" = cc."case_barcode"
),
snora_per_sample AS (    -- log10-transformed average SNORA31 counts ( +1 )
    SELECT "sample_barcode",
           LOG(10, AVG("HTSeq__Counts") + 1)  AS "snora31_log10"
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"
    WHERE  "gene_name" = 'SNORA31'
    GROUP BY "sample_barcode"
),
mirna_per_sample AS (    -- average RPM per miRNA per sample
    SELECT "sample_barcode",
           "mirna_id",
           AVG("reads_per_million_miRNA_mapped") AS "avg_miRNA_rpm"
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."MIRNASEQ_EXPRESSION"
    GROUP BY "sample_barcode", "mirna_id"
),
joined AS (              -- put everything together (only cohort samples)
    SELECT cs."sample_barcode",
           mps."mirna_id",
           sps."snora31_log10",
           mps."avg_miRNA_rpm"
    FROM   cohort_samples      cs
    JOIN   snora_per_sample    sps ON sps."sample_barcode"  = cs."sample_barcode"
    JOIN   mirna_per_sample    mps ON mps."sample_barcode"  = cs."sample_barcode"
)
SELECT
       "mirna_id",
       COUNT(*)                                              AS "n_samples",
       CORR("snora31_log10" , "avg_miRNA_rpm")               AS "pearson_r",
       CORR("snora31_log10" , "avg_miRNA_rpm")
         * SQRT(COUNT(*) - 2)
         / NULLIF(SQRT(1 - POWER(CORR("snora31_log10","avg_miRNA_rpm"),2)),0)  AS "t_stat"
FROM   joined
GROUP BY "mirna_id"
HAVING COUNT(*) > 25
   AND ABS(CORR("snora31_log10","avg_miRNA_rpm")) BETWEEN 0.3 AND 1.0
ORDER BY ABS("pearson_r") DESC NULLS LAST;