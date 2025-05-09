/*  RNA-seq expression (FPKM-UQ) for MDM2, TP53, CDKN1A and CCNE1
    in BLCA patients that harbour a CDKN2A mutation,
    together with key clinical data from GDC Release 39          */

WITH cdkn2a_mutant_cases AS (
    SELECT DISTINCT
           "case_barcode"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
)

SELECT
       e."case_barcode"                                                     AS "case_barcode",

       /* gene-wise FPKM-UQ values                                             */
       MAX( CASE WHEN e."gene_name" ILIKE 'MDM2%'   THEN e."HTSeq__FPKM_UQ" END ) AS "MDM2_FPKM_UQ",
       MAX( CASE WHEN e."gene_name" ILIKE 'TP53%'   THEN e."HTSeq__FPKM_UQ" END ) AS "TP53_FPKM_UQ",
       MAX( CASE WHEN e."gene_name" ILIKE 'CDKN1A%' THEN e."HTSeq__FPKM_UQ" END ) AS "CDKN1A_FPKM_UQ",
       MAX( CASE WHEN e."gene_name" ILIKE 'CCNE1%'  THEN e."HTSeq__FPKM_UQ" END ) AS "CCNE1_FPKM_UQ",

       /* selected clinical attributes                                         */
       c."demo__gender"                    AS "gender",
       c."demo__race"                      AS "race",
       c."demo__ethnicity"                 AS "ethnicity",
       c."demo__vital_status"              AS "vital_status",
       c."diag__ajcc_pathologic_stage"     AS "ajcc_pathologic_stage",
       c."diag__ajcc_clinical_stage"       AS "ajcc_clinical_stage",
       c."demo__age_at_index"              AS "age_at_index_years"

FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28"          e
JOIN   cdkn2a_mutant_cases                               m
       ON e."case_barcode" = m."case_barcode"
LEFT  JOIN TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"         c
       ON e."case_barcode" = c."submitter_id"

WHERE  e."project_short_name" = 'TCGA-BLCA'

GROUP  BY
       e."case_barcode",
       c."demo__gender",
       c."demo__race",
       c."demo__ethnicity",
       c."demo__vital_status",
       c."diag__ajcc_pathologic_stage",
       c."diag__ajcc_clinical_stage",
       c."demo__age_at_index"

ORDER  BY
       e."case_barcode";