/*  Bladder-cancer (TCGA-BLCA) cases that harbour a CDKN2A mutation:
      – mutation class & type (from several masked-MAF releases)
      – clinical details (gender, vital-status, days-to-death; GDC R39)
      – FPKM expression of MDM2, TP53, CDKN1A, CCNE1 (RNA-seq R35)      */

WITH cdkn2a_mutations AS (          -- 1. collect BLCA-specific CDKN2A mutations
    SELECT *  FROM (
        SELECT  "case_barcode",
                "Variant_Classification",
                "Variant_Type"
        FROM    TCGA.TCGA_VERSIONED.MASKED_SOMATIC_MUTATION_HG38_GDC_R39
        WHERE   "project_short_name" = 'TCGA-BLCA'
          AND   "Hugo_Symbol"        = 'CDKN2A'
        UNION ALL
        SELECT  "case_barcode",
                "Variant_Classification",
                "Variant_Type"
        FROM    TCGA.TCGA_VERSIONED.MASKED_SOMATIC_MUTATION_HG38_GDC_R36
        WHERE   "project_short_name" = 'TCGA-BLCA'
          AND   "Hugo_Symbol"        = 'CDKN2A'
        UNION ALL
        SELECT  "case_barcode",
                "Variant_Classification",
                "Variant_Type"
        FROM    TCGA.TCGA_VERSIONED.MASKED_SOMATIC_MUTATION_HG38_GDC_R35
        WHERE   "project_short_name" = 'TCGA-BLCA'
          AND   "Hugo_Symbol"        = 'CDKN2A'
        UNION ALL
        SELECT  "case_barcode",
                "Variant_Classification",
                "Variant_Type"
        FROM    TCGA.TCGA_VERSIONED.MASKED_SOMATIC_MUTATION_HG38_GDC_R34
        WHERE   "project_short_name" = 'TCGA-BLCA'
          AND   "Hugo_Symbol"        = 'CDKN2A'
    )
),

clinical AS (                      -- 2. demographic & survival information
    SELECT  "submitter_id"       AS "case_barcode",
            "demo__gender"       AS "gender",
            "demo__vital_status" AS "vital_status",
            "demo__days_to_death"AS "days_to_death"
    FROM    TCGA.TCGA_VERSIONED.CLINICAL_GDC_R39
),

expr_matrix AS (                   -- 3. FPKM for the four downstream genes
    SELECT
        SUBSTR("sample_barcode",1,12)                                         AS "case_barcode",
        MAX(CASE WHEN "gene_name" = 'MDM2'   THEN "fpkm_unstranded" END)      AS "expr_MDM2",
        MAX(CASE WHEN "gene_name" = 'TP53'   THEN "fpkm_unstranded" END)      AS "expr_TP53",
        MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN "fpkm_unstranded" END)      AS "expr_CDKN1A",
        MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN "fpkm_unstranded" END)      AS "expr_CCNE1"
    FROM   TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35
    WHERE  "project_short_name" = 'TCGA-BLCA'
       AND "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP  BY SUBSTR("sample_barcode",1,12)
)

SELECT DISTINCT
       m."case_barcode",
       m."Variant_Classification"  AS "mutation_classification",
       m."Variant_Type"            AS "mutation_type",
       c."gender",
       c."vital_status",
       c."days_to_death",
       e."expr_MDM2",
       e."expr_TP53",
       e."expr_CDKN1A",
       e."expr_CCNE1"
FROM   cdkn2a_mutations m
LEFT   JOIN clinical     c ON c."case_barcode" = m."case_barcode"
LEFT   JOIN expr_matrix  e ON e."case_barcode" = m."case_barcode"
ORDER  BY m."case_barcode";