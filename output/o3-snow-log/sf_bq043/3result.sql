/*  RNA expression (normalized counts) for MDM2, TP53, CDKN1A and CCNE1
    together with selected clinical attributes
    in CDKN2A-mutant bladder-cancer (TCGA-BLCA) cases                */

SELECT
    clin."submitter_id"                                   AS "case_barcode",

    /*  gene-wise normalized RNA-seq counts (wide format)  */
    MAX(CASE WHEN expr."HGNC_gene_symbol" = 'MDM2'   THEN expr."normalized_count" END) AS "MDM2_norm_cnt",
    MAX(CASE WHEN expr."HGNC_gene_symbol" = 'TP53'   THEN expr."normalized_count" END) AS "TP53_norm_cnt",
    MAX(CASE WHEN expr."HGNC_gene_symbol" = 'CDKN1A' THEN expr."normalized_count" END) AS "CDKN1A_norm_cnt",
    MAX(CASE WHEN expr."HGNC_gene_symbol" = 'CCNE1'  THEN expr."normalized_count" END) AS "CCNE1_norm_cnt",

    /*  key clinical fields (GDC release 39)               */
    clin."diag__ajcc_pathologic_stage",
    clin."diag__tissue_or_organ_of_origin",
    clin."demo__gender",
    clin."demo__race",
    clin."demo__ethnicity",
    clin."demo__vital_status"

FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"  sm          -- somatic mutations (hg19, Feb 2017)
JOIN TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02"            expr        -- RNA-seq (hg19) normalized counts
      ON sm."case_barcode" = expr."case_barcode"
JOIN TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"                   clin        -- clinical data (GDC release 39)
      ON clin."submitter_id" = sm."case_barcode"

WHERE sm."project_short_name" = 'TCGA-BLCA'          -- bladder cancer project
  AND sm."Hugo_Symbol"        = 'CDKN2A'             -- cases carrying ≥1 CDKN2A mutation
  AND expr."HGNC_gene_symbol" IN ('MDM2','TP53','CDKN1A','CCNE1')

GROUP BY
    clin."submitter_id",
    clin."diag__ajcc_pathologic_stage",
    clin."diag__tissue_or_organ_of_origin",
    clin."demo__gender",
    clin."demo__race",
    clin."demo__ethnicity",
    clin."demo__vital_status"

ORDER BY clin."submitter_id";