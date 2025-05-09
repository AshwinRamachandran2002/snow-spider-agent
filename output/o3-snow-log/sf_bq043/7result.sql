/*  RNA-seq expression (FPKM & TPM) of MDM2, TP53, CDKN1A, CCNE1
    in TCGA-BLCA patients whose tumours harbour a CDKN2A mutation,
    together with selected clinical attributes (GDC Release 39).   */

WITH "CDKN2A_mutated_cases" AS (                 -- patients with ≥1 CDKN2A mutation
    SELECT DISTINCT
           "case_barcode"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
),

"genes" AS (                                     -- list of genes of interest
    SELECT column1 AS "gene_name"
    FROM   ( VALUES ('MDM2'),
                    ('TP53'),
                    ('CDKN1A'),
                    ('CCNE1') ) AS v(column1)
),

"expr" AS (                                      -- primary-tumour RNA-seq values
    SELECT
           "case_barcode",
           "gene_name",
           "fpkm_unstranded",
           "tpm_unstranded"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "sample_type_name"   = 'Primary Tumor'
      AND  "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
)

SELECT
       m."case_barcode",
       g."gene_name"                     AS "gene",
       e."fpkm_unstranded",
       e."tpm_unstranded",
       c."demo__gender"                  AS "gender",
       c."demo__race"                    AS "race",
       c."demo__ethnicity"               AS "ethnicity",
       c."demo__vital_status"            AS "vital_status",
       c."diag__year_of_diagnosis"       AS "year_of_diagnosis",
       c."diag__ajcc_pathologic_stage"   AS "ajcc_pathologic_stage"
FROM   "CDKN2A_mutated_cases"           m
CROSS  JOIN "genes"                     g
LEFT   JOIN "expr"                      e
       ON  e."case_barcode" = m."case_barcode"
       AND e."gene_name"   = g."gene_name"
JOIN   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"   c
       ON  c."submitter_id" = m."case_barcode"
WHERE  c."proj__project_id" = 'TCGA-BLCA'
ORDER  BY m."case_barcode",
          g."gene_name";