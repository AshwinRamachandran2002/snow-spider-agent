/*  Retrieve bladder-cancer (TCGA-BLCA) patients that harbour a CDKN2A mutation
    together with clinical information and expression of four downstream genes.   */

WITH cdkn2a_mut AS (                      /* 1.  Collect all BLCA CDKN2A mutations
                                             from every MASKED-SNV table that
                                             contains patient barcodes.            */
    SELECT DISTINCT
           "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM (
          SELECT "case_barcode","Variant_Classification","Variant_Type"
          FROM TCGA.TCGA_VERSIONED.MASKED_SOMATIC_MUTATION_HG38_GDC_R39
          WHERE UPPER("Hugo_Symbol") = 'CDKN2A' AND "project_short_name" = 'TCGA-BLCA'
          UNION ALL
          SELECT "case_barcode","Variant_Classification","Variant_Type"
          FROM TCGA.TCGA_VERSIONED.MASKED_SOMATIC_MUTATION_HG38_GDC_R36
          WHERE UPPER("Hugo_Symbol") = 'CDKN2A' AND "project_short_name" = 'TCGA-BLCA'
          UNION ALL
          SELECT "case_barcode","Variant_Classification","Variant_Type"
          FROM TCGA.TCGA_VERSIONED.MASKED_SOMATIC_MUTATION_HG38_GDC_R35
          WHERE UPPER("Hugo_Symbol") = 'CDKN2A' AND "project_short_name" = 'TCGA-BLCA'
          UNION ALL
          SELECT "case_barcode","Variant_Classification","Variant_Type"
          FROM TCGA.TCGA_VERSIONED.MASKED_SOMATIC_MUTATION_HG38_GDC_R34
          WHERE UPPER("Hugo_Symbol") = 'CDKN2A' AND "project_short_name" = 'TCGA-BLCA'
    )
),

clinical AS (                             /* 2.  Clinical demographics & outcome   */
    SELECT
        "submitter_id"       AS "case_barcode",
        "demo__gender",
        "demo__vital_status",
        "demo__days_to_death"
    FROM TCGA.TCGA_VERSIONED.CLINICAL_GDC_R39
),

rseq AS (                                 /* 3.  TPM expression of four genes       */
    SELECT
        SUBSTRING("sample_barcode",1,12)       AS "case_barcode",
        "gene_name",
        AVG("tpm_unstranded")                  AS "tpm"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R39
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY SUBSTRING("sample_barcode",1,12), "gene_name"
),

expr_pivot AS (                           /* 4.  One row per patient with TPMs      */
    SELECT
        "case_barcode",
        MAX(CASE WHEN "gene_name" = 'MDM2'   THEN "tpm" END) AS "MDM2_TPM",
        MAX(CASE WHEN "gene_name" = 'TP53'   THEN "tpm" END) AS "TP53_TPM",
        MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN "tpm" END) AS "CDKN1A_TPM",
        MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN "tpm" END) AS "CCNE1_TPM"
    FROM rseq
    GROUP BY "case_barcode"
)

SELECT                                    /* 5.  Final combined result              */
       m."case_barcode",
       m."Variant_Classification",
       m."Variant_Type",
       c."demo__gender"        AS "gender",
       c."demo__vital_status"  AS "vital_status",
       c."demo__days_to_death" AS "days_to_death",
       e."MDM2_TPM",
       e."TP53_TPM",
       e."CDKN1A_TPM",
       e."CCNE1_TPM"
FROM cdkn2a_mut  m
LEFT JOIN clinical    c ON c."case_barcode" = m."case_barcode"
LEFT JOIN expr_pivot  e ON e."case_barcode" = m."case_barcode"
ORDER BY m."case_barcode";