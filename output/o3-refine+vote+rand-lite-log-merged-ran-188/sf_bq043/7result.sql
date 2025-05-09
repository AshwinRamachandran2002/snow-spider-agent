/*  RNA expression (normalized_count) for MDM2, TP53, CDKN1A and CCNE1
    together with selected GDC Release 39 clinical attributes
    in TCGA-BLCA patients whose tumours harbour a CDKN2A mutation        */

WITH mutated_cases AS (   -- TCGA-BLCA cases with ≥1 CDKN2A mutation
    SELECT DISTINCT "case_barcode"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
),

expr_pivot AS (          -- pivot gene-level RNA-seq values (hg19 release)
    SELECT
        e."case_barcode",
        MAX(CASE WHEN e."HGNC_gene_symbol" = 'MDM2'   THEN e."normalized_count" END) AS "MDM2_norm",
        MAX(CASE WHEN e."HGNC_gene_symbol" = 'TP53'   THEN e."normalized_count" END) AS "TP53_norm",
        MAX(CASE WHEN e."HGNC_gene_symbol" = 'CDKN1A' THEN e."normalized_count" END) AS "CDKN1A_norm",
        MAX(CASE WHEN e."HGNC_gene_symbol" = 'CCNE1'  THEN e."normalized_count" END) AS "CCNE1_norm"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02"  e
    WHERE  e."project_short_name" = 'TCGA-BLCA'
      AND  e."HGNC_gene_symbol"  IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY e."case_barcode"
)

SELECT
    m."case_barcode"                        AS "Case_Barcode",
    c."demo__gender"                        AS "Gender",
    c."demo__race"                          AS "Race",
    c."demo__ethnicity"                     AS "Ethnicity",
    c."demo__vital_status"                  AS "Vital_Status",
    c."diag__ajcc_pathologic_stage"         AS "AJCC_Pathologic_Stage",
    e."MDM2_norm",
    e."TP53_norm",
    e."CDKN1A_norm",
    e."CCNE1_norm"
FROM        mutated_cases                                   m
LEFT JOIN   expr_pivot                                      e  ON m."case_barcode" = e."case_barcode"
LEFT JOIN   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"          c  ON m."case_barcode" = c."submitter_id"
ORDER BY    "Case_Barcode";