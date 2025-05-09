/* -----------------------------------------------------------
   TCGA-BLCA : CDKN2A–mutant cases ‑ mutation, clinical (R-39),
               and cohort-level RNA-seq (R-39)
   ----------------------------------------------------------- */
WITH mutation_tbl AS (                 -- 1. CDKN2A mutations
    SELECT
        "case_barcode",
        LISTAGG(DISTINCT "Variant_Classification", '; ')
            WITHIN GROUP (ORDER BY "Variant_Classification")  AS "cdkn2a_mutation_types"
    FROM TCGA.TCGA_VERSIONED.SOMATIC_MUTATION_HG38_GDC_R10
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "Hugo_Symbol"       = 'CDKN2A'
    GROUP BY "case_barcode"
),

clinical_tbl AS (                      -- 2. Clinical release-39
    SELECT
        "submitter_id"     AS "case_barcode",
        "demo__gender"     AS "gender",
        "demo__vital_status"  AS "vital_status",
        "demo__days_to_death" AS "days_to_death"
    FROM TCGA.TCGA_VERSIONED.CLINICAL_GDC_R39
),

expr_avg AS (                          -- 3. Cohort-level mean TPM
    SELECT
        "gene_name",
        AVG("tpm_unstranded") AS "avg_tpm"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R39
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY "gene_name"
),

expr_pivot AS (                        -- 4. Pivot to one row
    SELECT
        MAX(CASE WHEN "gene_name" = 'MDM2'   THEN "avg_tpm" END) AS "MDM2_tpm",
        MAX(CASE WHEN "gene_name" = 'TP53'   THEN "avg_tpm" END) AS "TP53_tpm",
        MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN "avg_tpm" END) AS "CDKN1A_tpm",
        MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN "avg_tpm" END) AS "CCNE1_tpm"
    FROM expr_avg
)

SELECT
    m."case_barcode",
    m."cdkn2a_mutation_types",
    c."gender",
    c."vital_status",
    c."days_to_death",
    e."MDM2_tpm",
    e."TP53_tpm",
    e."CDKN1A_tpm",
    e."CCNE1_tpm"
FROM mutation_tbl  AS m
LEFT JOIN clinical_tbl AS c
       ON m."case_barcode" = c."case_barcode"
CROSS JOIN expr_pivot  AS e
ORDER BY m."case_barcode";