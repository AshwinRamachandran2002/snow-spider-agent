/*  RNA expression (HTSeq_FPKM) for MDM2, TP53, CDKN1A and CCNE1
    plus key clinical attributes (GDC Clinical Release 39)
    for bladder-cancer (TCGA-BLCA) patients harbouring CDKN2A mutations      */

WITH mutated_cases AS (  -------------------------------------------------------
    SELECT DISTINCT "case_barcode"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
),

expr AS (                -------------------------------------------------------
    SELECT
           r."case_barcode",
           MAX(CASE WHEN r."gene_name" = 'MDM2'   THEN r."HTSeq__FPKM" END) AS "MDM2_fpkm",
           MAX(CASE WHEN r."gene_name" = 'TP53'   THEN r."HTSeq__FPKM" END) AS "TP53_fpkm",
           MAX(CASE WHEN r."gene_name" = 'CDKN1A' THEN r."HTSeq__FPKM" END) AS "CDKN1A_fpkm",
           MAX(CASE WHEN r."gene_name" = 'CCNE1'  THEN r."HTSeq__FPKM" END) AS "CCNE1_fpkm"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28"  r
    WHERE  r."project_short_name" = 'TCGA-BLCA'
      AND  r."gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
      AND  r."case_barcode" IN (SELECT "case_barcode" FROM mutated_cases)
    GROUP BY r."case_barcode"
),

clin AS (               --------------------------------------------------------
    SELECT
           c."submitter_id"                 AS "case_barcode",
           c."demo__gender"                AS "gender",
           c."demo__race"                  AS "race",
           c."demo__ethnicity"             AS "ethnicity",
           c."demo__vital_status"          AS "vital_status",
           c."diag__ajcc_pathologic_stage" AS "ajcc_pathologic_stage"
    FROM   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39" c
    WHERE  c."proj__project_id" = 'TCGA-BLCA'
      AND  c."submitter_id" IN (SELECT "case_barcode" FROM mutated_cases)
)

SELECT
       m."case_barcode",
       e."MDM2_fpkm",
       e."TP53_fpkm",
       e."CDKN1A_fpkm",
       e."CCNE1_fpkm",
       cl."gender",
       cl."race",
       cl."ethnicity",
       cl."vital_status",
       cl."ajcc_pathologic_stage"
FROM   mutated_cases m
LEFT   JOIN expr e
       ON m."case_barcode" = e."case_barcode"
LEFT   JOIN clin cl
       ON m."case_barcode" = cl."case_barcode"
ORDER  BY m."case_barcode";