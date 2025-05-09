-- Top five protein-coding genes with the highest expression variance
WITH solid_cases AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R40"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND ILIKE("sample_type_name", '%Solid%Tissue%Normal%')
),
solid_normal_rows AS (
    SELECT
        "gene_name",
        "fpkm_uq_unstranded"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R40"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND ILIKE("sample_type_name", '%Solid%Tissue%Normal%')
      AND "gene_type" = 'protein_coding'
      AND "case_barcode" IN (SELECT "case_barcode" FROM solid_cases)
      AND "gene_name" IS NOT NULL
)
SELECT
    "gene_name",
    VAR_SAMP("fpkm_uq_unstranded") AS "expr_var"
FROM solid_normal_rows
GROUP BY "gene_name"
ORDER BY "expr_var" DESC NULLS LAST
LIMIT 5;