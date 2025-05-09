/*  Bladder-cancer (TCGA-BLCA) cases that harbour at least one CDKN2A mutation.
    – collect mutation category/type
    – add clinical information (gender, vital status, days-to-death)
    – append TPM expression for MDM2, TP53, CDKN1A, CCNE1                  */

WITH mutation_pool AS (  -- combine all masked-somatic releases that retain case_barcode
    SELECT "case_barcode",
           "project_short_name",
           "Hugo_Symbol",
           "Variant_Classification",
           "Variant_Type"
    FROM  TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R39"
    UNION ALL
    SELECT "case_barcode",
           "project_short_name",
           "Hugo_Symbol",
           "Variant_Classification",
           "Variant_Type"
    FROM  TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R36"
    UNION ALL
    SELECT "case_barcode",
           "project_short_name",
           "Hugo_Symbol",
           "Variant_Classification",
           "Variant_Type"
    FROM  TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R35"
),

cdkn2a_mut AS (          -- BLCA patients with ≥1 CDKN2A mutation
    SELECT DISTINCT
           "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM   mutation_pool
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
),

clinical AS (            -- clinical data (Release-39)
    SELECT
           "submitter_id"        AS "case_barcode",
           "demo__gender"        AS "gender",
           "demo__vital_status"  AS "vital_status",
           "demo__days_to_death" AS "days_to_death"
    FROM   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"
),

expr AS (                -- gene-expression TPM values (Release-35 RNA-seq)
    SELECT
           SUBSTR("sample_barcode",1,12)                                      AS "case_barcode",
           MAX(CASE WHEN "gene_name" = 'MDM2'   THEN "tpm_unstranded" END) AS "mdm2_tpm",
           MAX(CASE WHEN "gene_name" = 'TP53'   THEN "tpm_unstranded" END) AS "tp53_tpm",
           MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN "tpm_unstranded" END) AS "cdkn1a_tpm",
           MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN "tpm_unstranded" END) AS "ccne1_tpm"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE  "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP  BY SUBSTR("sample_barcode",1,12)
)

SELECT
       m."case_barcode"            AS "patient_id",
       m."Variant_Classification",
       m."Variant_Type",
       c."gender",
       c."vital_status",
       c."days_to_death",
       e."mdm2_tpm",
       e."tp53_tpm",
       e."cdkn1a_tpm",
       e."ccne1_tpm"
FROM   cdkn2a_mut m
LEFT   JOIN clinical c ON m."case_barcode" = c."case_barcode"
LEFT   JOIN expr     e ON m."case_barcode" = e."case_barcode"
ORDER  BY m."case_barcode";