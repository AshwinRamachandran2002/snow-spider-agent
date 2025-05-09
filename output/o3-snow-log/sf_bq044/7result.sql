/* ---------------------------------------------------------------------------
   Bladder-cancer (TCGA-BLCA) cases carrying CDKN2A mutations
   – mutation class, clinical information (GDC Release-39),
     and project-level FPKM-UQ expression of four downstream genes
--------------------------------------------------------------------------- */
WITH cdkn2a_mut AS (      -- 1) one row per patient with CDKN2A mutation(s)
    SELECT
        m."case_barcode"                                                         AS "patient_id",
        LISTAGG(DISTINCT m."Variant_Classification", ',')
              WITHIN GROUP (ORDER BY m."Variant_Classification")                 AS "mutation_types"
    FROM TCGA.TCGA_VERSIONED."SOMATIC_MUTATION_HG38_GDC_R10"  m
    WHERE m."project_short_name" = 'TCGA-BLCA'
      AND m."Hugo_Symbol"        = 'CDKN2A'
    GROUP BY m."case_barcode"
),

clin AS (                -- 2) clinical release-39 information
    SELECT
        c."submitter_id"        AS "patient_id",
        c."demo__gender"        AS "gender",
        c."demo__vital_status"  AS "vital_status",
        c."demo__days_to_death" AS "days_to_death"
    FROM TCGA.TCGA_VERSIONED."CLINICAL_GDC_R39" c
),

expr AS (                 -- 3) project-level average FPKM-UQ for the 4 genes
    SELECT
        "gene_name",
        AVG("fpkm_uq_unstranded")                                    AS "avg_fpkm_uq"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE "project_short_name" = 'TCGA-BLCA'
      AND "gene_name" IN ('MDM2','TP53','CDKN1A','CCNE1')
    GROUP BY "gene_name"
),

expr_pivot AS (           -- 4) pivot averages into separate columns
    SELECT
        MAX(CASE WHEN "gene_name" = 'MDM2'   THEN "avg_fpkm_uq" END) AS "MDM2_FPKM_UQ",
        MAX(CASE WHEN "gene_name" = 'TP53'   THEN "avg_fpkm_uq" END) AS "TP53_FPKM_UQ",
        MAX(CASE WHEN "gene_name" = 'CDKN1A' THEN "avg_fpkm_uq" END) AS "CDKN1A_FPKM_UQ",
        MAX(CASE WHEN "gene_name" = 'CCNE1'  THEN "avg_fpkm_uq" END) AS "CCNE1_FPKM_UQ"
    FROM expr
)

SELECT
    m."patient_id",
    m."mutation_types",          -- CDKN2A mutation class(es)
    c."gender",
    c."vital_status",
    c."days_to_death",
    e."MDM2_FPKM_UQ",
    e."TP53_FPKM_UQ",
    e."CDKN1A_FPKM_UQ",
    e."CCNE1_FPKM_UQ"
FROM cdkn2a_mut  m
LEFT JOIN clin        c  ON c."patient_id" = m."patient_id"
CROSS JOIN expr_pivot e          -- one row (project-level averages)
ORDER BY m."patient_id";