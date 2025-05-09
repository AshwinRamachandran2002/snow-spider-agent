/*  CDKN2A-mutated bladder-cancer (TCGA-BLCA) cases:
    – mutation classification/type (MC3 set)
    – clinical outcome (GDC release-39)
    – expression of MDM2, TP53, CDKN1A, CCNE1 (RNA-seq hg19 2017-02)        */

WITH cdkn2a_mut AS (                         -- 1) CDKN2A mutations (MC3)
    SELECT
        "case_barcode",
        LISTAGG( DISTINCT "Variant_Classification"||':'||"Variant_Type",
                 '; ' )
            WITHIN GROUP (ORDER BY "Variant_Classification"||':'||"Variant_Type")
            AS "mutation_types"
    FROM   TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG19_MC3_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "Hugo_Symbol"        = 'CDKN2A'
    GROUP  BY "case_barcode"
),

clinical AS (                                -- 2) Clinical data (R-39)
    SELECT
        "submitter_id"        AS "case_barcode",
        "demo__gender"        AS "gender",
        "demo__vital_status"  AS "vital_status",
        "demo__days_to_death" AS "days_to_death"
    FROM   TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39"
),

expr AS (                                    -- 3) Gene expression (RNA-seq)
    SELECT
        "case_barcode",
        MAX(CASE WHEN "HGNC_gene_symbol" = 'MDM2'   THEN "normalized_count" END)
            AS "MDM2_expr",
        MAX(CASE WHEN "HGNC_gene_symbol" = 'TP53'   THEN "normalized_count" END)
            AS "TP53_expr",
        MAX(CASE WHEN "HGNC_gene_symbol" = 'CDKN1A' THEN "normalized_count" END)
            AS "CDKN1A_expr",
        MAX(CASE WHEN "HGNC_gene_symbol" = 'CCNE1'  THEN "normalized_count" END)
            AS "CCNE1_expr"
    FROM   TCGA.TCGA_VERSIONED."RNASEQ_HG19_GDC_2017_02"
    WHERE  "project_short_name" = 'TCGA-BLCA'
      AND  "HGNC_gene_symbol" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP  BY "case_barcode"
)

SELECT
    'TCGA-BLCA'             AS "project",
    m."case_barcode",
    m."mutation_types",
    c."gender",
    c."vital_status",
    c."days_to_death",
    e."MDM2_expr",
    e."TP53_expr",
    e."CDKN1A_expr",
    e."CCNE1_expr"
FROM   cdkn2a_mut m
LEFT   JOIN clinical c ON m."case_barcode" = c."case_barcode"
LEFT   JOIN expr     e ON m."case_barcode" = e."case_barcode"
ORDER  BY m."case_barcode";