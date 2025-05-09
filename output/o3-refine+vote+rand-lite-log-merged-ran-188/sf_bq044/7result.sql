/*  Bladder-cancer (TCGA-BLCA) patients whose tumours carry a CDKN2A mutation.
    For every such patient:
        • report the CDKN2A mutation class & type
        • pull clinical outcome variables from GDC Release 39
        • pull expression of four downstream genes (MDM2, TP53, CDKN1A, CCNE1)
*/
WITH cdkn2a_mut AS (      -- CDKN2A–mutated cases (masked-MAF Release 35, has barcodes)
    SELECT DISTINCT
           "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM   TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R35"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
),
expr AS (                  -- gene-expression rows for the four downstream genes
    SELECT
           SUBSTR("sample_barcode",1,12)               AS "case_barcode",
           "sample_barcode",
           "HGNC_gene_symbol"                          AS "gene_symbol",
           "normalized_count"                          AS "expression_level"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "HGNC_gene_symbol" IN ('MDM2','TP53','CDKN1A','CCNE1')
)
SELECT
       m."case_barcode",
       m."Variant_Classification"      AS "cdkn2a_variant_class",
       m."Variant_Type"                AS "cdkn2a_variant_type",
       c."demo__gender"                AS "gender",
       c."demo__vital_status"          AS "vital_status",
       c."demo__days_to_death"         AS "days_to_death",
       e."sample_barcode",
       e."gene_symbol",
       e."expression_level"
FROM          cdkn2a_mut                       m
LEFT JOIN     TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"    c
       ON     c."submitter_id" = m."case_barcode"       -- Release 39 clinical data
JOIN          expr                                   e
       ON     e."case_barcode" = m."case_barcode"
ORDER BY
       m."case_barcode",
       e."gene_symbol";