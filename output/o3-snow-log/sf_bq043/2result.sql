/*  RNA expression (normalized counts) for MDM2, TP53, CDKN1A, and CCNE1
    in bladder-cancer (TCGA-BLCA) patients that harbor a CDKN2A mutation,
    together with key clinical attributes from GDC Release 39              */

WITH mutant_cases AS (           -- TCGA-BLCA patients with a CDKN2A mutation
    SELECT DISTINCT "case_barcode"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
),

expr AS (                        -- RNA-seq expression for the requested genes
    SELECT
           e."case_barcode",
           e."HGNC_gene_symbol"  AS "gene_name",
           e."normalized_count"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02"  e
    WHERE  e."project_short_name" = 'TCGA-BLCA'
      AND  e."HGNC_gene_symbol"  IN ('MDM2','TP53','CDKN1A','CCNE1')
),

clin AS (                        -- Clinical data (GDC Release 39)
    SELECT
           c."submitter_id"                AS "case_barcode",
           c."demo__gender"                AS "gender",
           c."demo__race"                  AS "race",
           c."demo__ethnicity"             AS "ethnicity",
           c."demo__vital_status"          AS "vital_status",
           c."diag__year_of_diagnosis"     AS "diagnosis_year",
           c."diag__ajcc_pathologic_stage" AS "ajcc_pathologic_stage",
           c."primary_site"                AS "primary_site"
    FROM   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"  c
)

SELECT
       e."case_barcode"          AS "Patient_Barcode",
       e."gene_name"             AS "Gene",
       e."normalized_count"      AS "Normalized_Count",
       c."gender"                AS "Gender",
       c."race"                  AS "Race",
       c."ethnicity"             AS "Ethnicity",
       c."vital_status"          AS "Vital_Status",
       c."diagnosis_year"        AS "Diagnosis_Year",
       c."ajcc_pathologic_stage" AS "AJCC_Pathologic_Stage",
       c."primary_site"          AS "Primary_Site"
FROM   expr            e
JOIN   mutant_cases    m  ON e."case_barcode" = m."case_barcode"
LEFT   JOIN clin       c  ON e."case_barcode" = c."case_barcode"
ORDER  BY e."case_barcode",
          e."gene_name";