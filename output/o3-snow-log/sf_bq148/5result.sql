SELECT
    "gene_name",
    VAR_POP("fpkm_uq_unstranded") AS "variance_fpkm_uq_unstranded"
FROM
    TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R40
WHERE
    "project_short_name" = 'TCGA-BRCA'
    AND "sample_type_name" = 'Solid Tissue Normal'
    AND "gene_type" = 'protein_coding'
    AND "gene_name" IS NOT NULL
    AND "fpkm_uq_unstranded" IS NOT NULL
GROUP BY
    "gene_name"
HAVING
    COUNT(*) > 1              -- ensure variance is computable
ORDER BY
    "variance_fpkm_uq_unstranded" DESC NULLS LAST
LIMIT 5;