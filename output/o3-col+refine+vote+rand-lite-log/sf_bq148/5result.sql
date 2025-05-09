/* top-variance protein-coding genes in TCGA-BRCA solid-tissue normal samples */
WITH solid_normals AS (
    SELECT
        "gene_name",
        "fpkm_uq_unstranded"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R40"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name" ILIKE '%Solid%Tissue%Normal%'
      AND "gene_type"        = 'protein_coding'
      AND "gene_name"        IS NOT NULL
      AND "fpkm_uq_unstranded" IS NOT NULL
)
SELECT
    "gene_name",
    VAR_SAMP("fpkm_uq_unstranded") AS "variance_fpkm_uq",
    AVG("fpkm_uq_unstranded")      AS "mean_fpkm_uq",
    COUNT(*)                       AS "normal_sample_count"
FROM solid_normals
GROUP BY "gene_name"
HAVING COUNT(*) > 1                      -- need ≥2 samples to compute variance
ORDER BY "variance_fpkm_uq" DESC NULLS LAST
LIMIT 5;