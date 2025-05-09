/*  Normalised RNA-Seq counts (hg19, release 2017-02) for MDM2, TP53, CDKN1A and CCNE1
    in TCGA-BLCA cases that harbour a CDKN2A mutation, together with GDC-R39 clinical data */
SELECT
       expr."project_short_name",
       expr."case_barcode",
       expr."HGNC_gene_symbol"            AS "gene_name",
       expr."normalized_count"            AS "expression_normalised",
       clin."demo__gender",
       clin."demo__race",
       clin."demo__ethnicity",
       clin."demo__vital_status",
       clin."diag__ajcc_pathologic_stage",
       clin."diag__ajcc_clinical_stage"
FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02"  expr
JOIN  ( SELECT DISTINCT "case_barcode"
        FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
        WHERE "project_short_name" = 'TCGA-BLCA'
          AND UPPER("Hugo_Symbol")     = 'CDKN2A'
      ) mut
      ON  mut."case_barcode" = expr."case_barcode"
LEFT JOIN TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"      clin
      ON  clin."submitter_id" = expr."case_barcode"
WHERE  expr."project_short_name"   = 'TCGA-BLCA'
  AND  UPPER(expr."HGNC_gene_symbol") IN ('MDM2','TP53','CDKN1A','CCNE1')
ORDER BY
       expr."case_barcode",
       expr."HGNC_gene_symbol";