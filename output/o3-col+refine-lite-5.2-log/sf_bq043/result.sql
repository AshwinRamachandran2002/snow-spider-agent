/*  RNA expression of MDM2, TP53, CDKN1A and CCNE1 together with key clinical
    attributes for TCGA‑BLCA tumour samples whose cases harbour CDKN2A mutations  
    (mutations: hg19 MC3 Feb‑2017; clinical: GDC Release 39).                  */

WITH "mutated_samples" AS (            -- CDKN2A‑mutated tumour samples
    SELECT DISTINCT
           "case_barcode",
           "sample_barcode_tumor" AS "sample_barcode"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"       = 'CDKN2A'
),

"rna" AS (                             -- RNA‑seq expression for genes of interest
    SELECT
           "case_barcode",
           "sample_barcode",
           "gene_name",
           "HTSeq__FPKM"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
),

"clinical" AS (                        -- clinical (GDC R39)
    SELECT
           "submitter_id"        AS "case_barcode",
           "demo__gender"        AS "gender",
           "demo__race"          AS "race",
           "demo__vital_status"  AS "vital_status",
           "demo__year_of_birth" AS "year_of_birth",
           "demo__year_of_death" AS "year_of_death"
    FROM   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"
)

SELECT
       m."case_barcode",
       m."sample_barcode",
       c."gender",
       c."race",
       c."vital_status",
       c."year_of_birth",
       c."year_of_death",
       MAX(CASE WHEN r."gene_name" = 'MDM2'   THEN r."HTSeq__FPKM" END) AS "MDM2_FPKM",
       MAX(CASE WHEN r."gene_name" = 'TP53'   THEN r."HTSeq__FPKM" END) AS "TP53_FPKM",
       MAX(CASE WHEN r."gene_name" = 'CDKN1A' THEN r."HTSeq__FPKM" END) AS "CDKN1A_FPKM",
       MAX(CASE WHEN r."gene_name" = 'CCNE1'  THEN r."HTSeq__FPKM" END) AS "CCNE1_FPKM"
FROM   "mutated_samples" m
LEFT  JOIN "rna"      r ON m."case_barcode"   = r."case_barcode"
                       AND m."sample_barcode" = r."sample_barcode"
LEFT  JOIN "clinical" c ON m."case_barcode"   = c."case_barcode"
GROUP BY
       m."case_barcode",
       m."sample_barcode",
       c."gender",
       c."race",
       c."vital_status",
       c."year_of_birth",
       c."year_of_death"
ORDER BY
       m."case_barcode" ASC,
       m."sample_barcode" ASC;