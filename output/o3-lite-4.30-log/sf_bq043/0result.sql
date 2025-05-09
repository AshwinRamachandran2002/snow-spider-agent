/*  RNA‑Seq FPKM (4‑decimal) for MDM2, TP53, CDKN1A, CCNE1
    plus clinical details for TCGA‑BLCA cases carrying a CDKN2A mutation   */

WITH mutated_cases AS (    -- patients with ≥1 CDKN2A mutation
    SELECT DISTINCT "case_barcode"
    FROM   "TCGA"."TCGA_VERSIONED"."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
),

expr_raw AS (              -- RNA‑Seq rows (Primary Tumor only) for the 4 genes
    SELECT
        r."case_barcode",
        r."gene_name",
        r."fpkm_unstranded" AS "fpkm"
    FROM   "TCGA"."TCGA_VERSIONED"."RNASEQ_HG38_GDC_R39" r
    JOIN   mutated_cases mc
           ON r."case_barcode" = mc."case_barcode"
    WHERE  r."sample_type_name" = 'Primary Tumor'
      AND  r."gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
),

expr_avg AS (              -- average FPKM per case × gene (handles multi‑aliquot)
    SELECT
        "case_barcode",
        "gene_name",
        AVG("fpkm") AS "fpkm"
    FROM  expr_raw
    GROUP BY "case_barcode", "gene_name"
),

expr_pivot AS (            -- pivot gene names to individual columns
    SELECT
        "case_barcode",
        MAX(CASE WHEN "gene_name" = 'MDM2'   THEN ROUND("fpkm",4) END) AS "mdm2_fpkm",
        MAX(CASE WHEN "gene_name" = 'TP53'   THEN ROUND("fpkm",4) END) AS "tp53_fpkm",
        MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN ROUND("fpkm",4) END) AS "cdkn1a_fpkm",
        MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN ROUND("fpkm",4) END) AS "ccne1_fpkm"
    FROM expr_avg
    GROUP BY "case_barcode"
)

SELECT
    m."case_barcode"                               AS case_id,
    COALESCE(e."mdm2_fpkm",   0) AS mdm2_fpkm,
    COALESCE(e."tp53_fpkm",   0) AS tp53_fpkm,
    COALESCE(e."cdkn1a_fpkm", 0) AS cdkn1a_fpkm,
    COALESCE(e."ccne1_fpkm",  0) AS ccne1_fpkm,
    ROUND(c."diag__age_at_diagnosis",4)            AS age_at_diagnosis_days,
    c."demo__gender"                               AS gender,
    c."demo__vital_status"                         AS vital_status,
    c."diag__ajcc_pathologic_stage"                AS tumor_stage
FROM   mutated_cases                       m
LEFT   JOIN expr_pivot                     e ON m."case_barcode" = e."case_barcode"
LEFT   JOIN "TCGA"."TCGA_VERSIONED"."CLINICAL_GDC_R39" c
       ON m."case_barcode" = c."submitter_id"
ORDER BY case_id;