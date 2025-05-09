/*  Expression (FPKM‑UQ) of MDM2, TP53, CDKN1A, CCNE1 in TCGA‑BLCA
    cases carrying a CDKN2A mutation, plus selected clinical data
    (GDC Release 39).                                             */

WITH mut_cases AS (
    SELECT DISTINCT "case_barcode"
    FROM   TCGA.TCGA_VERSIONED.SOMATIC_MUTATION_HG19_MC3_2017_02
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"       = 'CDKN2A'
),
rna AS (
    SELECT
        "case_barcode",
        "gene_name",
        "fpkm_uq_unstranded"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R39
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
      AND "sample_type_name" ILIKE '%Tumor%'     -- tumour RNA‑seq only
)
SELECT
    m."case_barcode"                                                            AS case_id,
    ROUND( MAX( CASE WHEN r."gene_name" = 'MDM2'   THEN r."fpkm_uq_unstranded" END ), 4 ) AS mdm2_fpkm,
    ROUND( MAX( CASE WHEN r."gene_name" = 'TP53'   THEN r."fpkm_uq_unstranded" END ), 4 ) AS tp53_fpkm,
    ROUND( MAX( CASE WHEN r."gene_name" = 'CDKN1A' THEN r."fpkm_uq_unstranded" END ), 4 ) AS cdkn1a_fpkm,
    ROUND( MAX( CASE WHEN r."gene_name" = 'CCNE1'  THEN r."fpkm_uq_unstranded" END ), 4 ) AS ccne1_fpkm,
    c."diag__age_at_diagnosis"                                                   AS age_at_diagnosis_days,
    c."demo__gender"                                                             AS gender,
    c."demo__vital_status"                                                       AS vital_status,
    c."diag__ajcc_pathologic_stage"                                              AS tumor_stage
FROM       mut_cases                     m
LEFT JOIN  rna                           r  ON r."case_barcode" = m."case_barcode"
LEFT JOIN  TCGA.TCGA_VERSIONED.CLINICAL_GDC_R39 c
           ON c."submitter_id" = m."case_barcode"
GROUP BY
    m."case_barcode",
    c."diag__age_at_diagnosis",
    c."demo__gender",
    c."demo__vital_status",
    c."diag__ajcc_pathologic_stage"
ORDER BY
    case_id;