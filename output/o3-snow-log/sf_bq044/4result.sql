/*  -------------------------------------------------------------------------
    Bladder-cancer (TCGA-BLCA) cases that harbour a CDKN2A mutation
    -------------------------------------------------------------------------
    • Pull every BLCA case that contains at least one CDKN2A mutation
      (SOMATIC_MUTATION_HG38_GDC_R10).

    • For each case, collapse the CDKN2A “Variant_Classification” values into
      a semi-colon-separated list so we can see all mutation types in one
      field (“cdkn2a_mutation_types”).

    • Add the Release-39 clinical attributes (gender, vital-status,
      days-to-death) by linking the case-barcode to CLINICAL_GDC_R39
      (submitter_id ≙ case_barcode).

    • Fetch gene-expression (FPKM, unstranded) of four downstream genes
      (MDM2, TP53, CDKN1A and CCNE1) from the Release-35 RNA-seq table.
      These values are pivoted into individual columns.

    • Return one row per patient with all requested information.
   ------------------------------------------------------------------------- */
WITH cdkn2a_mut AS (           ----------------  CDKN2A-mutant BLCA cases
    SELECT
        "case_barcode",
        LISTAGG(DISTINCT "Variant_Classification", ';')
            AS "cdkn2a_mutation_types"
    FROM TCGA.TCGA_VERSIONED.SOMATIC_MUTATION_HG38_GDC_R10
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Hugo_Symbol"       = 'CDKN2A'
    GROUP BY "case_barcode"
),
expr AS (                      ----------------  Gene-expression (FPKM)
    SELECT
        "case_barcode",
        MAX(CASE WHEN "gene_name" = 'MDM2'   THEN "fpkm_unstranded" END) AS "MDM2_fpkm",
        MAX(CASE WHEN "gene_name" = 'TP53'   THEN "fpkm_unstranded" END) AS "TP53_fpkm",
        MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN "fpkm_unstranded" END) AS "CDKN1A_fpkm",
        MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN "fpkm_unstranded" END) AS "CCNE1_fpkm"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY "case_barcode"
)
SELECT
    m."case_barcode",
    m."cdkn2a_mutation_types",
    cl."demo__gender"        AS "gender",
    cl."demo__vital_status"  AS "vital_status",
    cl."demo__days_to_death" AS "days_to_death",
    e."MDM2_fpkm",
    e."TP53_fpkm",
    e."CDKN1A_fpkm",
    e."CCNE1_fpkm"
FROM cdkn2a_mut                                       AS m
LEFT JOIN TCGA.TCGA_VERSIONED.CLINICAL_GDC_R39        AS cl
       ON m."case_barcode" = cl."submitter_id"
LEFT JOIN expr                                        AS e
       ON m."case_barcode" = e."case_barcode"
ORDER BY m."case_barcode";