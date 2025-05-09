--Top-five protein-coding genes with the greatest expression variance
--across “Solid Tissue Normal” samples from TCGA-BRCA (RNA-seq R40 release)
WITH solid_tissue_normal AS (
    SELECT
        "gene_name",
        "fpkm_uq_unstranded"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R40"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name" = 'Solid Tissue Normal'
      AND "gene_type" = 'protein_coding'        -- limit to protein-coding genes
      AND "gene_name" IS NOT NULL               -- exclude records lacking gene symbol
)
SELECT
    "gene_name",
    VAR_SAMP("fpkm_uq_unstranded") AS "expr_variance"
FROM solid_tissue_normal
GROUP BY "gene_name"
ORDER BY "expr_variance" DESC NULLS LAST
LIMIT 5;