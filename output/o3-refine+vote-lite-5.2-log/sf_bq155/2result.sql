WITH "clinical_filter" AS (   -- BRCA cases meeting age and stage criteria
    SELECT DISTINCT "case_barcode"
    FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL_V1"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "age_at_diagnosis" <= 80
      AND "pathologic_stage" IN ('Stage I','Stage II','Stage IIA')
), 

"snora31_expr" AS (          -- log10‑transformed RNA‑Seq expression of SNORA31
    SELECT
        r."sample_barcode",
        LOG(10, AVG(r."HTSeq__Counts") + 1)  AS "snora31_expr"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION" r
    JOIN "clinical_filter" c
      ON c."case_barcode" = r."case_barcode"
    WHERE r."project_short_name" = 'TCGA-BRCA'
      AND r."gene_name" = 'SNORA31'
    GROUP BY r."sample_barcode"
),

"mirna_expr" AS (            -- average miRNA‑Seq expression per sample & miRNA
    SELECT
        m."sample_barcode",
        m."mirna_id",
        AVG(m."reads_per_million_miRNA_mapped") AS "mirna_expr"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION" m
    JOIN "clinical_filter" c
      ON c."case_barcode" = m."case_barcode"
    WHERE m."project_short_name" = 'TCGA-BRCA'
    GROUP BY m."sample_barcode", m."mirna_id"
),

"paired_data" AS (           -- join gene & miRNA expression by sample
    SELECT
        g."snora31_expr",
        mi."mirna_id",
        mi."mirna_expr"
    FROM "snora31_expr"  g
    JOIN "mirna_expr"    mi
      ON g."sample_barcode" = mi."sample_barcode"
)

SELECT
    "mirna_id",
    COUNT(*)                                             AS "n_samples",
    CORR("snora31_expr","mirna_expr")                    AS "pearson_r",
    CORR("snora31_expr","mirna_expr") * 
        SQRT(COUNT(*) - 2) / 
        SQRT(1 - POWER(CORR("snora31_expr","mirna_expr"),2))  AS "t_stat"
FROM "paired_data"
GROUP BY "mirna_id"
HAVING COUNT(*) > 25
   AND ABS(CORR("snora31_expr","mirna_expr")) BETWEEN 0.3 AND 1.0
ORDER BY ABS("t_stat") DESC NULLS LAST;