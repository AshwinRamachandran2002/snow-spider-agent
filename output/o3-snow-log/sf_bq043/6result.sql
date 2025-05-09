/*  RNA expression (normalized counts) for MDM2, TP53, CDKN1A and CCNE1,
    plus selected clinical fields, in TCGA-BLCA patients that carry
    a CDKN2A somatic mutation  (GDC Release-39 clinical data)          */

SELECT
       e."case_barcode"                                                     AS "case_barcode",
       MAX(CASE WHEN e."HGNC_gene_symbol" = 'MDM2'   THEN e."normalized_count" END) AS "MDM2_expr",
       MAX(CASE WHEN e."HGNC_gene_symbol" = 'TP53'   THEN e."normalized_count" END) AS "TP53_expr",
       MAX(CASE WHEN e."HGNC_gene_symbol" = 'CDKN1A' THEN e."normalized_count" END) AS "CDKN1A_expr",
       MAX(CASE WHEN e."HGNC_gene_symbol" = 'CCNE1'  THEN e."normalized_count" END) AS "CCNE1_expr",
       c."demo__gender"                                                     AS "gender",
       c."demo__race"                                                       AS "race",
       c."demo__ethnicity"                                                  AS "ethnicity",
       c."demo__vital_status"                                               AS "vital_status",
       c."diag__ajcc_pathologic_stage"                                      AS "ajcc_pathologic_stage"
FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02"            e           -- RNA-seq (hg19, 2017-02)
JOIN   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"  m           -- Somatic mutations (MC3, hg19)
           ON e."case_barcode" = m."case_barcode"
JOIN   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"                   c           -- Clinical (GDC Release-39)
           ON c."submitter_id" = e."case_barcode"
WHERE  e."project_short_name" = 'TCGA-BLCA'                                   -- bladder cancer project
  AND  e."HGNC_gene_symbol" IN ('MDM2','TP53','CDKN1A','CCNE1')               -- genes of interest
  AND  m."project_short_name" = 'TCGA-BLCA'                                   -- ensure same project in mutation table
  AND  m."Hugo_Symbol"        = 'CDKN2A'                                      -- CDKN2A-mutated cases
GROUP BY
       e."case_barcode",
       c."demo__gender",
       c."demo__race",
       c."demo__ethnicity",
       c."demo__vital_status",
       c."diag__ajcc_pathologic_stage"
ORDER BY
       e."case_barcode";