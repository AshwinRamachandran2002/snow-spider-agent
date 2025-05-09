/*  -------------------------------------------------------------
    Bladder-cancer cases (TCGA-BLCA) carrying a CDKN2A mutation
    -------------------------------------------------------------
    • Mutation details are taken from GDC Release-10 somatic-mutation table
      “SOMATIC_MUTATION_HG38_GDC_R10”.
    • Clinical attributes come from the GDC Release-39 clinical table
      “CLINICAL_GDC_R39”.
    • Gene-expression values (HTSeq FPKM) for the four downstream genes
      (MDM2, TP53, CDKN1A, CCNE1) are gathered from the RNA-seq snapshot
      “RNASEQ_HG38_GDC_R28”.
-----------------------------------------------------------------*/
WITH cdkn2a_mut AS (      -- 1) patients harbouring CDKN2A mutations
    SELECT
        m."case_barcode",
        LISTAGG(DISTINCT m."Variant_Classification", ',')
            WITHIN GROUP (ORDER BY m."Variant_Classification")  AS "variant_classifications",
        LISTAGG(DISTINCT m."Variant_Type",          ',')
            WITHIN GROUP (ORDER BY m."Variant_Type")            AS "variant_types"
    FROM TCGA.TCGA_VERSIONED.SOMATIC_MUTATION_HG38_GDC_R10  m
    WHERE m."project_short_name" = 'TCGA-BLCA'
      AND m."Hugo_Symbol"        = 'CDKN2A'
    GROUP BY m."case_barcode"
),
clin AS (                 -- 2) clinical data (GDC Release-39)
    SELECT
        c."submitter_id"              AS "case_barcode",
        c."demo__gender"              AS "gender",
        c."demo__vital_status"        AS "vital_status",
        c."demo__days_to_death"       AS "days_to_death"
    FROM TCGA.TCGA_VERSIONED.CLINICAL_GDC_R39  c
),
expr AS (                 -- 3) expression values for the four genes
    SELECT
        e."case_barcode",
        MAX(CASE WHEN e."gene_name" = 'MDM2'   THEN e."HTSeq__FPKM" END) AS "MDM2_FPKM",
        MAX(CASE WHEN e."gene_name" = 'TP53'   THEN e."HTSeq__FPKM" END) AS "TP53_FPKM",
        MAX(CASE WHEN e."gene_name" = 'CDKN1A' THEN e."HTSeq__FPKM" END) AS "CDKN1A_FPKM",
        MAX(CASE WHEN e."gene_name" = 'CCNE1'  THEN e."HTSeq__FPKM" END) AS "CCNE1_FPKM"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28  e
    WHERE e."project_short_name" = 'TCGA-BLCA'
      AND e."gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY e."case_barcode"
)
SELECT
    m."case_barcode",
    m."variant_classifications",
    m."variant_types",
    c."gender",
    c."vital_status",
    c."days_to_death",
    e."MDM2_FPKM",
    e."TP53_FPKM",
    e."CDKN1A_FPKM",
    e."CCNE1_FPKM"
FROM cdkn2a_mut  m
LEFT JOIN clin  c  ON c."case_barcode" = m."case_barcode"
LEFT JOIN expr  e  ON e."case_barcode" = m."case_barcode"
ORDER BY m."case_barcode";