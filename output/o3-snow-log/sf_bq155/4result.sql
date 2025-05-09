WITH clinical_filtered AS (                -- 1. TCGA-BRCA cases that satisfy the criteria
    SELECT DISTINCT
           "case_barcode"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis"   IS NOT NULL
      AND  "age_at_diagnosis"  <= 80
      AND  "pathologic_stage"  IN ('Stage I','Stage II','Stage IIA')
),
snora_per_case AS (                        -- 2. log10-transformed average SNORA31 RNA-Seq counts per case
    SELECT
           r."case_barcode",
           LOG(10 , AVG(r."HTSeq__Counts") + 1 )  AS "snora_log"
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
           JOIN clinical_filtered c
             ON c."case_barcode" = r."case_barcode"
    WHERE  r."project_short_name" = 'TCGA-BRCA'
      AND  r."gene_name" = 'SNORA31'
    GROUP  BY r."case_barcode"
),
mirna_per_case AS (                        -- 3. average miRNA read counts per miRNA per case
    SELECT
           m."case_barcode",
           m."mirna_id",
           AVG(m."read_count")                        AS "mirna_avg"
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.MIRNASEQ_EXPRESSION m
           JOIN clinical_filtered c
             ON c."case_barcode" = m."case_barcode"
    WHERE  m."project_short_name" = 'TCGA-BRCA'
    GROUP  BY m."case_barcode", m."mirna_id"
),
joined AS (                               -- 4. pair SNORA31 value with each miRNA value within the same case
    SELECT
           s."case_barcode",
           s."snora_log",
           p."mirna_id",
           p."mirna_avg"
    FROM   snora_per_case  s
           JOIN mirna_per_case p
             ON s."case_barcode" = p."case_barcode"
)
-- 5. correlation & t-statistic, keeping only requested pairs
SELECT
       "mirna_id",
       COUNT(*)                                     AS "n_samples",
       CORR("snora_log","mirna_avg")                AS "pearson_r",
       CORR("snora_log","mirna_avg") * SQRT(COUNT(*)-2)
       / NULLIF( SQRT(1 - POWER(CORR("snora_log","mirna_avg"),2)), 0 )
                                                   AS "t_statistic"
FROM   joined
GROUP  BY "mirna_id"
HAVING COUNT(*) > 25
   AND ABS( CORR("snora_log","mirna_avg") ) BETWEEN 0.3 AND 1.0
ORDER  BY "t_statistic" DESC NULLS LAST;