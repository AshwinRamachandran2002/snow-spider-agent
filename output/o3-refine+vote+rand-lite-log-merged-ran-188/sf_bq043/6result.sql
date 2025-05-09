/*  RNA-seq expression (HTSeq__FPKM, release R28) for four genes of interest
    in TCGA-BLCA cases that harbour at least one CDKN2A somatic mutation.
    Clinical attributes come from GDC clinical release R39.
*/
SELECT
       c."submitter_id"                        AS "case_barcode",
       c."demo__gender"                        AS "gender",
       c."demo__race"                          AS "race",
       c."demo__ethnicity"                     AS "ethnicity",
       c."demo__vital_status"                  AS "vital_status",
       c."diag__ajcc_pathologic_stage"         AS "pathologic_stage",
       c."diag__ajcc_clinical_stage"           AS "clinical_stage",
       c."diag__year_of_diagnosis"             AS "year_of_diagnosis",
       c."demo__days_to_death"                 AS "days_to_death",
       /* pivot-style gene expression */
       MAX(CASE WHEN e."gene_name" = 'MDM2'     THEN e."HTSeq__FPKM" END) AS "MDM2_FPKM",
       MAX(CASE WHEN e."gene_name" = 'TP53'     THEN e."HTSeq__FPKM" END) AS "TP53_FPKM",
       MAX(CASE WHEN e."gene_name" = 'CDKN1A'   THEN e."HTSeq__FPKM" END) AS "CDKN1A_FPKM",
       MAX(CASE WHEN e."gene_name" ILIKE 'CCNE1%' THEN e."HTSeq__FPKM" END) AS "CCNE1_FPKM"
FROM   "TCGA"."TCGA_VERSIONED"."CLINICAL_GDC_R39"           AS c
JOIN   "TCGA"."TCGA_VERSIONED"."RNASEQ_HG38_GDC_R28"        AS e
       ON  e."case_barcode"      = c."submitter_id"
LEFT JOIN (
       SELECT DISTINCT "case_barcode"
       FROM   "TCGA"."TCGA_VERSIONED"."SOMATIC_MUTATION_HG19_MC3_2017_02"
       WHERE  "project_short_name" = 'TCGA-BLCA'
         AND  "Hugo_Symbol"        = 'CDKN2A'
)                                                          AS m
       ON m."case_barcode" = c."submitter_id"
WHERE  c."proj__project_id"      = 'TCGA-BLCA'     -- keep bladder-cancer cases
  AND  m."case_barcode" IS NOT NULL                -- retain only CDKN2A-mutants
  AND  e."project_short_name"    = 'TCGA-BLCA'     -- RNA-seq rows from BLCA
GROUP BY
       c."submitter_id",
       c."demo__gender",
       c."demo__race",
       c."demo__ethnicity",
       c."demo__vital_status",
       c."diag__ajcc_pathologic_stage",
       c."diag__ajcc_clinical_stage",
       c."diag__year_of_diagnosis",
       c."demo__days_to_death"
ORDER BY
       c."submitter_id";