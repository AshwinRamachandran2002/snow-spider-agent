/* ---------------------------------------------------------------
   BLCA patients (TCGA-BLCA) harbouring CDKN2A mutations
   ---------------------------------------------------------------
   • Search four consecutive masked-mutation releases (R34-R39) to
     guarantee that CDKN2A-mutated BLCA cases are captured.
   • Summarise per-patient mutation “types” and “classifications”.
   • Add Release-39 clinical details (gender, vital-status, days-to-death).
   • Attach RNA-seq TPM values (Release-35) for MDM2, TP53, CDKN1A, CCNE1.
------------------------------------------------------------------*/
WITH all_mutations AS (   -- collect BLCA mutations from four releases
    SELECT "case_barcode", "project_short_name",
           "Variant_Type", "Variant_Classification", "Hugo_Symbol"
    FROM TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R39"
    UNION ALL
    SELECT "case_barcode", "project_short_name",
           "Variant_Type", "Variant_Classification", "Hugo_Symbol"
    FROM TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R36"
    UNION ALL
    SELECT "case_barcode", "project_short_name",
           "Variant_Type", "Variant_Classification", "Hugo_Symbol"
    FROM TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R35"
    UNION ALL
    SELECT "case_barcode", "project_short_name",
           "Variant_Type", "Variant_Classification", "Hugo_Symbol"
    FROM TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R34"
),
cdkn2a_mut AS (            -- BLCA patients mutated in CDKN2A
    SELECT
        "case_barcode",
        LISTAGG(DISTINCT "Variant_Type", ', ')
              WITHIN GROUP (ORDER BY "Variant_Type")           AS "variant_types",
        LISTAGG(DISTINCT "Variant_Classification", ', ')
              WITHIN GROUP (ORDER BY "Variant_Classification") AS "variant_classifications"
    FROM all_mutations
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND UPPER("Hugo_Symbol")  = 'CDKN2A'
    GROUP BY "case_barcode"
),
clinical AS (              -- Release-39 clinical attributes
    SELECT
        "submitter_id"       AS "case_barcode",
        "demo__gender"       AS "gender",
        "demo__vital_status" AS "vital_status",
        "demo__days_to_death"
    FROM TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"
),
rna AS (                    -- TPM expression for four downstream genes
    SELECT
        SUBSTR("sample_barcode", 1, 12) AS "case_barcode",
        "gene_name",
        "tpm_unstranded"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "gene_name" IN ('MDM2', 'TP53', 'CDKN1A', 'CCNE1')
)
-- assemble final table
SELECT
    m."case_barcode",
    m."variant_types",
    m."variant_classifications",
    c."gender",
    c."vital_status",
    c."demo__days_to_death" AS "days_to_death",
    MAX(CASE WHEN r."gene_name" = 'MDM2'   THEN r."tpm_unstranded" END) AS "MDM2_TPM",
    MAX(CASE WHEN r."gene_name" = 'TP53'   THEN r."tpm_unstranded" END) AS "TP53_TPM",
    MAX(CASE WHEN r."gene_name" = 'CDKN1A' THEN r."tpm_unstranded" END) AS "CDKN1A_TPM",
    MAX(CASE WHEN r."gene_name" = 'CCNE1'  THEN r."tpm_unstranded" END) AS "CCNE1_TPM"
FROM cdkn2a_mut m
LEFT JOIN clinical c ON m."case_barcode" = c."case_barcode"
LEFT JOIN rna      r ON m."case_barcode" = r."case_barcode"
GROUP BY
    m."case_barcode",
    m."variant_types",
    m."variant_classifications",
    c."gender",
    c."vital_status",
    c."demo__days_to_death"
ORDER BY m."case_barcode";