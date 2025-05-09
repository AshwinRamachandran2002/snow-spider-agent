WITH solid_tissue_normal AS (
    SELECT *
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name"   = 'Solid Tissue Normal'
      AND "gene_type"          = 'protein_coding'
)
SELECT
    "gene_name"                                          AS gene_symbol,
    ROUND(VAR_SAMP("HTSeq__FPKM_UQ"), 4)                 AS variance_fpkm_uq_unstranded
FROM solid_tissue_normal
GROUP BY "gene_name"
HAVING COUNT(*) >= 2
ORDER BY variance_fpkm_uq_unstranded DESC NULLS LAST,
         gene_symbol
LIMIT 5;