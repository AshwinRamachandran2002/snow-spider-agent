SELECT
    "gene_name",
    VAR_SAMP("fpkm_uq_unstranded") AS "expression_variance"
FROM
    TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R40
WHERE
    "project_short_name"   = 'TCGA-BRCA'
    AND "sample_type_name" = 'Solid Tissue Normal'
    AND "gene_type"        = 'protein_coding'
    AND "fpkm_uq_unstranded" IS NOT NULL
GROUP BY
    "gene_name"
ORDER BY
    "expression_variance" DESC NULLS LAST
LIMIT 5;