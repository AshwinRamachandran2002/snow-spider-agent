/*  Bladder-cancer (TCGA-BLCA) cases that harbour a CDKN2A mutation
    ------------------------------------------------------------------
    • mutation table   : MASKED_SOMATIC_MUTATION_HG38_GDC_R36  (has case barcodes)
    • clinical table   : CLINICAL_GDC_R29                      (Release-29 – retains submitter_id barcodes)
    • expression table : RNASEQ_HG38_GDC_R39                   (Release-39 RNA-seq TPMs)
*/

WITH cdkn2a_blca AS (            -- 1. BLCA cases with any CDKN2A mutation
    SELECT DISTINCT
        m."case_barcode",                         -- e.g. TCGA-XX-XXXX
        m."Variant_Classification",
        m."Variant_Type"
    FROM TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R36" m
    WHERE m."Hugo_Symbol"        = 'CDKN2A'
      AND m."project_short_name" = 'TCGA-BLCA'
),

clinical AS (                    -- 2. Clinical info (submitter_id is the case barcode)
    SELECT
        c."submitter_id"          AS "case_barcode",
        c."demo__gender",
        c."demo__vital_status",
        c."demo__days_to_death"
    FROM TCGA.TCGA_VERSIONED."CLINICAL_GDC_R29" c
),

expr_raw AS (                    -- 3. TPM values for four downstream genes
    SELECT
        SUBSTR(r."sample_barcode",1,12)         AS "case_barcode",
        r."gene_name",
        r."tpm_unstranded"                      AS "tpm"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R39" r
    WHERE r."gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
),

expr_pivot AS (                  -- 4. Pivot to one row per case
    SELECT
        "case_barcode",
        MAX(CASE WHEN "gene_name" = 'MDM2'   THEN "tpm" END) AS "MDM2_tpm",
        MAX(CASE WHEN "gene_name" = 'TP53'   THEN "tpm" END) AS "TP53_tpm",
        MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN "tpm" END) AS "CDKN1A_tpm",
        MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN "tpm" END) AS "CCNE1_tpm"
    FROM expr_raw
    GROUP BY "case_barcode"
)

-- 5. Merge mutation, clinical, and expression information
SELECT
    m."case_barcode",
    m."Variant_Classification",
    m."Variant_Type",
    c."demo__gender"        AS "gender",
    c."demo__vital_status"  AS "vital_status",
    c."demo__days_to_death" AS "days_to_death",
    e."MDM2_tpm",
    e."TP53_tpm",
    e."CDKN1A_tpm",
    e."CCNE1_tpm"
FROM cdkn2a_blca  m
LEFT JOIN clinical   c ON m."case_barcode" = c."case_barcode"
LEFT JOIN expr_pivot e ON m."case_barcode" = e."case_barcode"
ORDER BY m."case_barcode";