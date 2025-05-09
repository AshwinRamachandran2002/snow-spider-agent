/*  RNA expression for MDM2, TP53, CDKN1A and CCNE1 in TCGA-BLCA cases
    that harbour a CDKN2A mutation, together with selected clinical data
    (GDC clinical release 39).                                              */

WITH mutated_cases AS (
    SELECT DISTINCT
           "case_barcode"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
)

SELECT
    r."case_barcode"                         AS "case_id",
    r."HGNC_gene_symbol"                     AS "gene_name",
    r."normalized_count"                     AS "normalized_expression",
    c."demo__gender"                         AS "gender",
    c."demo__race"                           AS "race",
    c."demo__ethnicity"                      AS "ethnicity",
    c."demo__vital_status"                   AS "vital_status",
    c."diag__ajcc_pathologic_stage"          AS "ajcc_pathologic_stage",
    c."diag__ajcc_clinical_stage"            AS "ajcc_clinical_stage",
    c."demo__age_at_index"                   AS "age_at_index_years"
FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02"          r
JOIN   mutated_cases                                           m
          ON r."case_barcode" = m."case_barcode"
LEFT JOIN TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"              c
          ON r."case_barcode" = c."submitter_id"
WHERE  r."project_short_name" = 'TCGA-BLCA'
  AND  r."HGNC_gene_symbol" IN ('MDM2', 'TP53', 'CDKN1A', 'CCNE1')
ORDER BY
    r."case_barcode",
    r."HGNC_gene_symbol";