WITH UNION_RNASEQ AS (
    SELECT 
        "project_short_name",
        "gene_name",
        "gene_type",
        "fpkm_uq_unstranded",
        "sample_type_name"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R40
    
    UNION ALL
    
    SELECT 
        "project_short_name",
        "gene_name",
        "gene_type",
        "fpkm_uq_unstranded",
        "sample_type_name"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R39
),
BRCA_SOLID_NORMAL AS (
    SELECT *
    FROM UNION_RNASEQ
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name" = 'Solid Tissue Normal'
      AND "gene_type" = 'protein_coding'
      AND "fpkm_uq_unstranded" IS NOT NULL
)
SELECT
    "gene_name",
    VAR_POP("fpkm_uq_unstranded") AS "expression_variance"
FROM BRCA_SOLID_NORMAL
GROUP BY "gene_name"
ORDER BY "expression_variance" DESC NULLS LAST
LIMIT 5;