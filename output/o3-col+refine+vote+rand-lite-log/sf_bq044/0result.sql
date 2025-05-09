/*  ---------------------------------------------------------------
    Bladder-cancer (TCGA-BLCA) cases with a CDKN2A mutation
    – mutation consequence & type
    – clinical information (GDC Release 39)
    – expression (TPM) for MDM2, TP53, CDKN1A and CCNE1
    --------------------------------------------------------------- */
WITH cdkn2a_mut AS (                             -- 1. CDKN2A-mutated cases
    SELECT
        DISTINCT
        m."case_barcode",
        LISTAGG(DISTINCT m."Variant_Classification", '; ')
          WITHIN GROUP (ORDER BY m."Variant_Classification") AS "variant_classes",
        LISTAGG(DISTINCT m."Variant_Type", '; ')
          WITHIN GROUP (ORDER BY m."Variant_Type")           AS "variant_types"
    FROM   TCGA.TCGA_VERSIONED."MASKED_SOMATIC_MUTATION_HG38_GDC_R36" m
    WHERE  m."project_short_name" = 'TCGA-BLCA'
      AND  m."Hugo_Symbol"        = 'CDKN2A'
    GROUP  BY m."case_barcode"
),
clin AS (                                        -- 2. Clinical data (Release 39)
    SELECT
        c."submitter_id"          AS "case_barcode",
        c."demo__gender"          AS "gender",
        c."demo__vital_status"    AS "vital_status",
        c."demo__days_to_death"   AS "days_to_death"
    FROM   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39" c            -- R39 table
),
expr AS (                                        -- 3. Gene-expression records
    SELECT
        SUBSTR(r."sample_barcode",1,12) AS "case_barcode",     -- derive case id
        r."gene_name",
        r."tpm_unstranded"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35" r
    WHERE  r."gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
)
SELECT
    m."case_barcode",
    m."variant_classes",
    m."variant_types",
    c."gender",
    c."vital_status",
    c."days_to_death",
    MAX(CASE WHEN e."gene_name" = 'MDM2'   THEN e."tpm_unstranded" END) AS "MDM2_TPM",
    MAX(CASE WHEN e."gene_name" = 'TP53'   THEN e."tpm_unstranded" END) AS "TP53_TPM",
    MAX(CASE WHEN e."gene_name" = 'CDKN1A' THEN e."tpm_unstranded" END) AS "CDKN1A_TPM",
    MAX(CASE WHEN e."gene_name" = 'CCNE1'  THEN e."tpm_unstranded" END) AS "CCNE1_TPM"
FROM   cdkn2a_mut        m
LEFT   JOIN clin         c  ON c."case_barcode"  = m."case_barcode"
LEFT   JOIN expr         e  ON e."case_barcode"  = m."case_barcode"
GROUP  BY
    m."case_barcode",
    m."variant_classes",
    m."variant_types",
    c."gender",
    c."vital_status",
    c."days_to_death"
ORDER BY
    m."case_barcode";