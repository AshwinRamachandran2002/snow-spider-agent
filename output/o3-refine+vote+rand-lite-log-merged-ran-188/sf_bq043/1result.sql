/*  RNA-seq expression (FPKM) for MDM2, TP53, CDKN1A and CCNE1
    together with basic clinical data (GDC Release-39)
    in TCGA-BLCA cases that harbour any CDKN2A mutation               */

WITH mutated_cases AS (                       -- 1) BLCA cases with CDKN2A mutation
    SELECT DISTINCT
           "case_barcode"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"       ILIKE 'CDKN2A'                       -- includes CDKN2A & CDKN2AIPNL
),

expr_avg AS (                                -- 2) average FPKM per case & gene
    SELECT
        exp."case_barcode",
        exp."gene_name",
        AVG(exp."HTSeq__FPKM") AS "avg_fpkm"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28" exp
    WHERE  exp."project_short_name" = 'TCGA-BLCA'
      AND  exp."gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY exp."case_barcode", exp."gene_name"
),

clin AS (                                    -- 3) clinical information (GDC Release-39)
    SELECT DISTINCT
           "submitter_id"                AS "case_barcode",
           "demo__gender"               AS "gender",
           "demo__race"                 AS "race",
           "demo__ethnicity"            AS "ethnicity",
           "demo__vital_status"         AS "vital_status",
           "diag__year_of_diagnosis"    AS "year_of_dx",
           "diag__ajcc_pathologic_stage" AS "pathologic_stage"
    FROM   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"
    WHERE  "proj__project_id" = 'TCGA-BLCA'
)

-- 4) bring everything together & pivot genes into columns
SELECT
       m."case_barcode",
       c."gender",
       c."race",
       c."ethnicity",
       c."vital_status",
       c."year_of_dx",
       c."pathologic_stage",
       MAX(CASE WHEN e."gene_name" = 'MDM2'   THEN e."avg_fpkm" END) AS "MDM2_FPKM",
       MAX(CASE WHEN e."gene_name" = 'TP53'   THEN e."avg_fpkm" END) AS "TP53_FPKM",
       MAX(CASE WHEN e."gene_name" = 'CDKN1A' THEN e."avg_fpkm" END) AS "CDKN1A_FPKM",
       MAX(CASE WHEN e."gene_name" = 'CCNE1'  THEN e."avg_fpkm" END) AS "CCNE1_FPKM"
FROM   mutated_cases m
LEFT   JOIN expr_avg e  ON m."case_barcode" = e."case_barcode"
LEFT   JOIN clin     c  ON m."case_barcode" = c."case_barcode"
GROUP  BY m."case_barcode",
          c."gender",
          c."race",
          c."ethnicity",
          c."vital_status",
          c."year_of_dx",
          c."pathologic_stage"
ORDER BY m."case_barcode";