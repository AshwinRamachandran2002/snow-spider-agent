WITH eligible_cases AS (   -- 1) BRCA cases ≤80 yrs with Stage I / II / IIA
    SELECT DISTINCT
           "case_barcode"
    FROM   "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis"  <= 80
      AND ( "pathologic_stage" ILIKE 'Stage I%'      -- Stage I / IA / IB
         OR "pathologic_stage" ILIKE 'Stage II%' )   -- Stage II / IIA / IIB …
),
snora31_expr AS (          -- 2) per-case log10-transformed SNORA31 RNA-Seq
    SELECT
          "case_barcode",
          LOG(10, AVG("HTSeq__Counts" + 1)) AS "log10_snora31"
    FROM  "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_name"          = 'SNORA31'
      AND "case_barcode" IN (SELECT "case_barcode" FROM eligible_cases)
    GROUP BY "case_barcode"
),
mirna_expr AS (            -- 3) per-case average RPM for each miRNA
    SELECT
          "mirna_id",
          "case_barcode",
          AVG("reads_per_million_miRNA_mapped") AS "avg_rpm"
    FROM  "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "case_barcode" IN (SELECT "case_barcode" FROM eligible_cases)
    GROUP BY "mirna_id", "case_barcode"
),
joined AS (                -- 4) pair SNORA31 and miRNA values by case
    SELECT
          m."mirna_id",
          s."log10_snora31",
          m."avg_rpm"
    FROM mirna_expr m
    JOIN snora31_expr s
      ON m."case_barcode" = s."case_barcode"
),
stats AS (                 -- 5) Pearson r and sample size per miRNA
    SELECT
          "mirna_id",
          COUNT(*)                        AS "n_samples",
          CORR("log10_snora31","avg_rpm") AS "pearson_r"
    FROM joined
    GROUP BY "mirna_id"
),
filtered AS (              -- 6) retain miRNAs meeting n & |r| criteria, add t-stat
    SELECT
          "mirna_id",
          "n_samples",
          "pearson_r",
          ("pearson_r" * SQRT("n_samples" - 2))
          / NULLIF(SQRT(1 - POWER("pearson_r", 2)), 0) AS "t_statistic"
    FROM stats
    WHERE "n_samples" > 25
      AND ABS("pearson_r") BETWEEN 0.3 AND 1.0
)
SELECT
      "mirna_id",
      "n_samples"            AS "sample_size",
      ROUND("pearson_r", 4)  AS "pearson_r",
      ROUND("t_statistic",4) AS "t_statistic"
FROM   filtered
ORDER BY ABS("t_statistic") DESC NULLS LAST;