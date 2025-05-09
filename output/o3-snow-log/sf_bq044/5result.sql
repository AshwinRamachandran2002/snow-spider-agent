/*------------------------------------------------------------------------
   TCGA-BLCA patients carrying a CDKN2A (ENSG00000147889) mutation
   – mutation class & type (from any available TCGA somatic-mutation tables)
   – clinical data (GDC Release 39)
   – BLCA-wide FPKM-UQ expression of four downstream genes
     (MDM2, TP53, CDKN1A, CCNE1) taken from RNA-seq Release 35
------------------------------------------------------------------------*/

WITH  /*--- 1.  all CDKN2A mutations found in any TCGA mutation table ----*/
mut_raw AS (
    SELECT "case_barcode"       AS "case_id",
           "Variant_Classification",
           "Variant_Type"
    FROM TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R39"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Gene" ILIKE 'ENSG00000147889%'

    UNION ALL
    SELECT "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R35"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Gene" ILIKE 'ENSG00000147889%'

    UNION ALL
    SELECT "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R34"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Gene" ILIKE 'ENSG00000147889%'

    UNION ALL
    SELECT "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG38_GDC_R10"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Hugo_Symbol" = 'CDKN2A'

    UNION ALL
    SELECT "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG38_GDC_R7"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Hugo_Symbol" = 'CDKN2A'

    UNION ALL
    SELECT "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG38_GDC_R6"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Hugo_Symbol" = 'CDKN2A'

    UNION ALL
    SELECT "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Hugo_Symbol" = 'CDKN2A'

    UNION ALL
    SELECT "case_barcode",
           "Variant_Classification",
           "Variant_Type"
    FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_DCC_2017_02"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Hugo_Symbol" = 'CDKN2A'
),
/*--- 2. collapse to one row per patient --------------------------------*/
mut AS (
    SELECT
        "case_id"                              AS "submitter_id",
        MAX("Variant_Classification")          AS "cdkn2a_variant_class",
        MAX("Variant_Type")                    AS "cdkn2a_variant_type"
    FROM mut_raw
    GROUP BY "case_id"
),
/*--- 3. BLCA-wide expression of the four downstream genes --------------*/
expr AS (
    SELECT
        MAX(CASE WHEN "gene_name" = 'MDM2'   THEN "fpkm_uq_unstranded" END) AS "MDM2_FPKM_UQ",
        MAX(CASE WHEN "gene_name" = 'TP53'   THEN "fpkm_uq_unstranded" END) AS "TP53_FPKM_UQ",
        MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN "fpkm_uq_unstranded" END) AS "CDKN1A_FPKM_UQ",
        MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN "fpkm_uq_unstranded" END) AS "CCNE1_FPKM_UQ"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
)
/*--- 4. final join with clinical data ----------------------------------*/
SELECT
       mut."submitter_id",
       clin."demo__gender"        AS "gender",
       clin."demo__vital_status"  AS "vital_status",
       clin."demo__days_to_death" AS "days_to_death",
       mut."cdkn2a_variant_class",
       mut."cdkn2a_variant_type",
       expr."MDM2_FPKM_UQ",
       expr."TP53_FPKM_UQ",
       expr."CDKN1A_FPKM_UQ",
       expr."CCNE1_FPKM_UQ"
FROM mut
LEFT JOIN TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"  clin
       ON mut."submitter_id" = clin."submitter_id"
CROSS JOIN expr         -- same BLCA-wide expression values for every patient
ORDER BY mut."submitter_id";