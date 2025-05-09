WITH eligible_cases AS (   -- 1.  BRCA cases that satisfy age & stage filters
    SELECT DISTINCT 
           "case_barcode"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL_V1"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis"  <= 80
      AND  "pathologic_stage"  IN ('Stage I','Stage II','Stage IIA')
),

snora31_expression AS (    -- 2.  SNORA31 RNA‑Seq counts per case
    SELECT  
           SUBSTR("sample_barcode",1,12)  AS "case_barcode",
           AVG("HTSeq__Counts")           AS "raw_counts"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "gene_name"          = 'SNORA31'
    GROUP  BY SUBSTR("sample_barcode",1,12)
),

mirna_expression AS (      -- 3.  mean miRNA read counts (per miRNA / per case)
    SELECT  
           SUBSTR("sample_barcode",1,12)  AS "case_barcode",
           "mirna_id",
           AVG("read_count")              AS "mirna_cnt"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION"
    WHERE  "project_short_name" = 'TCGA-BRCA'
    GROUP  BY SUBSTR("sample_barcode",1,12), "mirna_id"
),

paired_data AS (           -- 4.  keep only cases passing clinical filters
    SELECT  
           m."mirna_id",
           LOG(10, s."raw_counts" + 1)    AS "log10_snora31",
           m."mirna_cnt"
    FROM   eligible_cases     ec
    JOIN   snora31_expression s  ON ec."case_barcode" = s."case_barcode"
    JOIN   mirna_expression   m  ON ec."case_barcode" = m."case_barcode"
)

-- 5.  correlation, sample‑size filter, |r| range filter & t‑statistic
SELECT  
       "mirna_id",
       COUNT(*)                                   AS "num_samples",
       CORR("log10_snora31","mirna_cnt")          AS "pearson_r",
       CORR("log10_snora31","mirna_cnt")
         * SQRT( COUNT(*) - 2 )
         / SQRT( 1 - POWER( CORR("log10_snora31","mirna_cnt"), 2) ) 
                                                  AS "t_statistic"
FROM   paired_data
GROUP  BY "mirna_id"
HAVING COUNT(*) > 25
   AND ABS( CORR("log10_snora31","mirna_cnt") ) BETWEEN 0.3 AND 1.0
ORDER  BY ABS("t_statistic") DESC NULLS LAST, "mirna_id";