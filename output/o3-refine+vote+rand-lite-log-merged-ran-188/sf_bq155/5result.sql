WITH
/* 1.  TCGA‑BRCA cases that meet the clinical filters */
clinical AS (
    SELECT "case_barcode"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL_V1"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "age_at_diagnosis"  <= 80
      AND  "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
),

/* 2.  Per‑sample log10‑transformed average RNA‑Seq expression of SNORA31 */
snora AS (
    SELECT  "sample_barcode",
            LOG(10 , AVG("HTSeq__Counts") + 1)  AS gene_expr      -- log10
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"
    WHERE   "project_short_name" = 'TCGA-BRCA'
      AND   "gene_name"          = 'SNORA31'
    GROUP BY "sample_barcode"
),

/* 3.  Per‑sample average miRNA expression (RPM) for every microRNA */
mirna AS (
    SELECT  "sample_barcode",
            "mirna_id",
            AVG("reads_per_million_miRNA_mapped") AS mirna_expr
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."MIRNASEQ_EXPRESSION"
    WHERE   "project_short_name" = 'TCGA-BRCA'
    GROUP BY "sample_barcode", "mirna_id"
),

/* 4.  Join gene & miRNA expression restricted to clinically‑filtered samples */
joined AS (
    SELECT  s."sample_barcode",
            m."mirna_id",
            s.gene_expr,
            m.mirna_expr
    FROM    snora  s
    JOIN    mirna  m   USING ("sample_barcode")
    JOIN    clinical c ON SUBSTR(s."sample_barcode",1,12) = c."case_barcode"
)

/* 5.  Compute Pearson r, sample size n, and t‑statistic for each miRNA */
SELECT  "mirna_id",
        n_samples                                        AS n,
        r,
        r * SQRT(n_samples - 2) / SQRT(1 - r * r)        AS t_statistic
FROM   (
        SELECT  "mirna_id",
                COUNT(*)                     AS n_samples,
                CORR(gene_expr, mirna_expr)  AS r
        FROM    joined
        GROUP BY "mirna_id"
       )
WHERE   n_samples > 25
  AND    ABS(r) BETWEEN 0.3 AND 1.0
ORDER  BY ABS(t_statistic) DESC NULLS LAST,
          "mirna_id";