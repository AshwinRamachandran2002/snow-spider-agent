/*  RNA expression of MDM2, TP53, CDKN1A and CCNE1 together with
    key clinical attributes for BLCA patients that harbor a CDKN2A
    mutation (MC3 hg19, Feb-2017) – using GDC Release 39 clinical data  */

WITH "mutated_cases" AS (          -- BLCA cases with a CDKN2A mutation
    SELECT DISTINCT
        "case_barcode"
    FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND UPPER("Hugo_Symbol") = 'CDKN2A'
),
"expression" AS (                  -- FPKM values for the four genes
    SELECT
        "case_barcode",
        MAX(CASE WHEN UPPER("gene_name") = 'MDM2'   THEN "fpkm_unstranded" END) AS "MDM2_FPKM",
        MAX(CASE WHEN UPPER("gene_name") = 'TP53'   THEN "fpkm_unstranded" END) AS "TP53_FPKM",
        MAX(CASE WHEN UPPER("gene_name") = 'CDKN1A' THEN "fpkm_unstranded" END) AS "CDKN1A_FPKM",
        MAX(CASE WHEN UPPER("gene_name") = 'CCNE1'  THEN "fpkm_unstranded" END) AS "CCNE1_FPKM"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R40"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND UPPER("gene_name") IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY "case_barcode"
),
"clinical" AS (                    -- selected clinical fields (GDC R39)
    SELECT
        "submitter_id"                  AS "case_barcode",
        "demo__gender",
        "demo__race",
        "demo__ethnicity",
        "demo__vital_status",
        "demo__age_at_index",
        "diag__year_of_diagnosis",
        "diag__ajcc_pathologic_stage",
        "diag__ajcc_clinical_stage"
    FROM TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"
    WHERE "proj__project_id" = 'TCGA-BLCA'
)
SELECT
    m."case_barcode",
    e."MDM2_FPKM",
    e."TP53_FPKM",
    e."CDKN1A_FPKM",
    e."CCNE1_FPKM",
    c."demo__gender"            AS "gender",
    c."demo__race"              AS "race",
    c."demo__ethnicity"         AS "ethnicity",
    c."demo__vital_status"      AS "vital_status",
    c."demo__age_at_index"      AS "age_at_index_years",
    c."diag__year_of_diagnosis",
    c."diag__ajcc_pathologic_stage",
    c."diag__ajcc_clinical_stage"
FROM "mutated_cases" m
LEFT JOIN "expression" e ON m."case_barcode" = e."case_barcode"
LEFT JOIN "clinical"  c ON m."case_barcode" = c."case_barcode"
ORDER BY m."case_barcode";