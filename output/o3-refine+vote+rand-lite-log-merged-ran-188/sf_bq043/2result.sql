/*  RNA-Seq expression (hg19 ‑ 2017_02) for MDM2, TP53, CDKN1A and CCNE1
    in bladder cancer (TCGA-BLCA) patients that harbour CDKN2A mutations,
    combined with selected clinical attributes from GDC Clinical Release 39  */

WITH cdkn2a_mut_cases AS (          -- BLCA patients with a CDKN2A mutation
    SELECT DISTINCT "case_barcode"
    FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Hugo_Symbol"        = 'CDKN2A'
),

expr AS (                           -- pivot the four genes into columns
    SELECT
        r."case_barcode",
        MAX(CASE WHEN r."HGNC_gene_symbol" = 'MDM2'   THEN r."normalized_count" END) AS "MDM2_expr",
        MAX(CASE WHEN r."HGNC_gene_symbol" = 'TP53'   THEN r."normalized_count" END) AS "TP53_expr",
        MAX(CASE WHEN r."HGNC_gene_symbol" = 'CDKN1A' THEN r."normalized_count" END) AS "CDKN1A_expr",
        MAX(CASE WHEN r."HGNC_gene_symbol" = 'CCNE1'  THEN r."normalized_count" END) AS "CCNE1_expr"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02" r
    JOIN cdkn2a_mut_cases m
      ON r."case_barcode" = m."case_barcode"
    WHERE r."HGNC_gene_symbol" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY r."case_barcode"
)

SELECT
    e."case_barcode",
    e."MDM2_expr",
    e."TP53_expr",
    e."CDKN1A_expr",
    e."CCNE1_expr",
    c."demo__gender"                AS "gender",
    c."demo__race"                  AS "race",
    c."demo__ethnicity"             AS "ethnicity",
    c."demo__vital_status"          AS "vital_status",
    c."diag__ajcc_pathologic_stage" AS "pathologic_stage"
FROM expr e
LEFT JOIN TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39" c
       ON e."case_barcode" = c."submitter_id"
ORDER BY e."case_barcode";