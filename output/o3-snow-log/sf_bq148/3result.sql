SELECT
    "gene_name",
    VAR_SAMP("fpkm_uq_unstranded") AS "variance_fpkm_uq"
FROM
    TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R40
WHERE
    "project_short_name" = 'TCGA-BRCA'            -- focus on BRCA project
    AND "sample_type_name" = 'Solid Tissue Normal'-- only “Solid Tissue Normal” samples
    AND "gene_type" = 'protein_coding'            -- restrict to protein-coding genes
    AND "fpkm_uq_unstranded" IS NOT NULL          -- exclude records without expression values
GROUP BY
    "gene_name"
ORDER BY
    "variance_fpkm_uq" DESC NULLS LAST            -- highest variance first
LIMIT 5;