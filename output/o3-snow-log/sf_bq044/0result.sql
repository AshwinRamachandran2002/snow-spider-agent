SELECT
    mut."case_barcode",
    mut."Variant_Classification"                            AS "mutation_type",
    clin."demo__gender"                                     AS "gender",
    clin."demo__vital_status"                               AS "vital_status",
    clin."demo__days_to_death"                              AS "days_to_death",
    MAX(CASE WHEN exp."gene_name" = 'MDM2'   THEN exp."fpkm_unstranded" END) AS "MDM2_fpkm",
    MAX(CASE WHEN exp."gene_name" = 'TP53'   THEN exp."fpkm_unstranded" END) AS "TP53_fpkm",
    MAX(CASE WHEN exp."gene_name" = 'CDKN1A' THEN exp."fpkm_unstranded" END) AS "CDKN1A_fpkm",
    MAX(CASE WHEN exp."gene_name" = 'CCNE1'  THEN exp."fpkm_unstranded" END) AS "CCNE1_fpkm"
FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG38_GDC_R10" mut
JOIN TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"               clin
  ON clin."submitter_id" = mut."case_barcode"
LEFT JOIN TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"       exp
  ON exp."project_short_name" = mut."project_short_name"
 AND exp."gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
WHERE mut."project_short_name" = 'TCGA-BLCA'
  AND mut."Hugo_Symbol"        = 'CDKN2A'
GROUP BY
    mut."case_barcode",
    mut."Variant_Classification",
    clin."demo__gender",
    clin."demo__vital_status",
    clin."demo__days_to_death"
ORDER BY
    mut."case_barcode";