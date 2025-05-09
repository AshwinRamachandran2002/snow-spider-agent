/*  For TCGA-BLCA (bladder cancer) patients carrying a CDKN2A mutation:           
    1. collect the distinct mutation effects seen in CDKN2A (MC3 HG19 DCC table)  
    2. add clinical data from GDC release 39 (gender, vital-status, days-to-death)
    3. append RNA-seq FPKM values (release 35) for the four downstream genes      
       MDM2, TP53, CDKN1A and CCNE1                                              
*/

WITH cdkn2a_mut AS (               -- 1)  mutation information
    SELECT
        "case_barcode",
        LISTAGG(DISTINCT "Variant_Classification", ', ')
            WITHIN GROUP (ORDER BY "Variant_Classification") 
            AS "cdkn2a_mutation_types"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_DCC_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
    GROUP BY "case_barcode"
),
clin AS (                          -- 2)  clinical details
    SELECT
        "submitter_id"        AS "case_barcode",
        "demo__gender"        AS "gender",
        "demo__vital_status"  AS "vital_status",
        "demo__days_to_death" AS "days_to_death"
    FROM   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"
),
expr AS (                          -- 3)  RNA-seq expression (FPKM) pivoted to columns
    SELECT
        "case_barcode",
        MAX(CASE WHEN "gene_name" = 'MDM2'   THEN "fpkm_unstranded" END) AS "MDM2_fpkm",
        MAX(CASE WHEN "gene_name" = 'TP53'   THEN "fpkm_unstranded" END) AS "TP53_fpkm",
        MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN "fpkm_unstranded" END) AS "CDKN1A_fpkm",
        MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN "fpkm_unstranded" END) AS "CCNE1_fpkm"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY "case_barcode"
)
SELECT
       m."case_barcode",
       m."cdkn2a_mutation_types",
       c."gender",
       c."vital_status",
       c."days_to_death",
       e."MDM2_fpkm",
       e."TP53_fpkm",
       e."CDKN1A_fpkm",
       e."CCNE1_fpkm"
FROM   cdkn2a_mut m
LEFT JOIN clin c  ON c."case_barcode"  = m."case_barcode"
LEFT JOIN expr e  ON e."case_barcode"  = m."case_barcode"
ORDER BY m."case_barcode";