WITH "STN_BCRA_R40" AS (
    SELECT
        "gene_name",
        "fpkm_uq_unstranded"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R40"
    WHERE "project_short_name"   = 'TCGA-BRCA'
      AND "sample_type_name"     = 'Solid Tissue Normal'
      AND "gene_type"            = 'protein_coding'
      AND "fpkm_uq_unstranded" IS NOT NULL
)

SELECT
    "gene_name",
    VAR_SAMP("fpkm_uq_unstranded") AS "var_fpkm_uq"
FROM "STN_BCRA_R40"
GROUP BY "gene_name"
ORDER BY "var_fpkm_uq" DESC NULLS LAST
LIMIT 5;