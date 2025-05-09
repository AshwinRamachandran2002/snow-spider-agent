WITH
/* --- 1.  Select BRCA cases that match age and stage criteria --- */
"CLIN_FILTER" AS (
    SELECT DISTINCT
           "case_barcode"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis"  <= 80
      AND  "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),

/* --- 2.  SNORA31 RNA-Seq expression (log10(Counts+1)) per sample --- */
"SNORA_EXPR" AS (
    SELECT
           r."sample_barcode",
           LOG(10, r."HTSeq__Counts" + 1)      AS "snora_log"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION" r
           JOIN "CLIN_FILTER" c
             ON r."case_barcode" = c."case_barcode"
    WHERE  r."gene_name" = 'SNORA31'
),

/* --- 3.  Average miRNA expression (RPM) per sample & miRNA --- */
"MIRNA_EXPR" AS (
    SELECT
           m."sample_barcode",
           m."mirna_id",
           AVG(m."reads_per_million_miRNA_mapped") AS "mirna_avg"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION" m
           JOIN "CLIN_FILTER" c
             ON m."case_barcode" = c."case_barcode"
    GROUP  BY m."sample_barcode", m."mirna_id"
),

/* --- 4.  Pair each miRNA value with matching SNORA31 value --- */
"PAIR_DATA" AS (
    SELECT
           s."snora_log",
           m."mirna_id",
           m."mirna_avg"
    FROM   "SNORA_EXPR"  s
           JOIN "MIRNA_EXPR" m
             ON s."sample_barcode" = m."sample_barcode"
),

/* --- 5.  Pearson correlation, sample count, t-statistic per miRNA --- */
"CORR_STAT" AS (
    SELECT
           "mirna_id",
           CORR("snora_log","mirna_avg")              AS "pearson_r",
           COUNT(*)                                   AS "n"
    FROM   "PAIR_DATA"
    GROUP  BY "mirna_id"
    HAVING COUNT(*) > 25
       AND ABS(CORR("snora_log","mirna_avg")) BETWEEN 0.3 AND 1.0
)

SELECT
       "mirna_id",
       "n",
       "pearson_r",
       /* t = r * sqrt(n - 2) / sqrt(1 - r^2) */
       "pearson_r" * SQRT("n" - 2) / SQRT(1 - POWER("pearson_r", 2)) AS "t_statistic"
FROM   "CORR_STAT"
ORDER  BY ABS("pearson_r") DESC NULLS LAST;