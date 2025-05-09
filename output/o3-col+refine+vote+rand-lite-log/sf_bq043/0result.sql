WITH mutant_cases AS (
    /* CDKN2A-mutant bladder cancer patients (TCGA-BLCA) */
    SELECT DISTINCT
           "case_barcode"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
),
expr AS (
    /* RNA-Seq expression of the four genes for those patients */
    SELECT
           r."case_barcode",
           r."HGNC_gene_symbol"   AS "gene_symbol",
           r."normalized_count"   AS "expr_value"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02" r
           JOIN mutant_cases m
             ON m."case_barcode" = r."case_barcode"
    WHERE  r."project_short_name" = 'TCGA-BLCA'
      AND  r."HGNC_gene_symbol" IN ('MDM2', 'TP53', 'CDKN1A', 'CCNE1')
)
/* Combine clinical information (GDC Release 39) with expression */
SELECT
       c."submitter_id"                          AS "patient_barcode",
       c."demo__gender"                          AS "gender",
       c."demo__race"                            AS "race",
       c."demo__ethnicity"                       AS "ethnicity",
       c."demo__vital_status"                    AS "vital_status",
       c."diag__ajcc_pathologic_stage"           AS "pathologic_stage",
       MAX(CASE WHEN e."gene_symbol" = 'MDM2'   THEN e."expr_value" END) AS "MDM2_expression",
       MAX(CASE WHEN e."gene_symbol" = 'TP53'   THEN e."expr_value" END) AS "TP53_expression",
       MAX(CASE WHEN e."gene_symbol" = 'CDKN1A' THEN e."expr_value" END) AS "CDKN1A_expression",
       MAX(CASE WHEN e."gene_symbol" = 'CCNE1'  THEN e."expr_value" END) AS "CCNE1_expression"
FROM   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39" c
       JOIN mutant_cases m
         ON m."case_barcode" = c."submitter_id"
       LEFT JOIN expr e
         ON e."case_barcode" = c."submitter_id"
GROUP BY
       c."submitter_id",
       c."demo__gender",
       c."demo__race",
       c."demo__ethnicity",
       c."demo__vital_status",
       c."diag__ajcc_pathologic_stage"
ORDER BY
       c."submitter_id";