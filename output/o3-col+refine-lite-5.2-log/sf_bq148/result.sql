/* Top 5 protein‑coding genes with the greatest expression variance
   (FPKM‑UQ) in “Solid Tissue Normal” samples from the TCGA‑BRCA project */
SELECT
    "gene_name",
    VAR_SAMP("HTSeq__FPKM_UQ") AS "var_fpkm_uq"
FROM
    TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28"
WHERE
    "project_short_name" = 'TCGA-BRCA'
    AND "sample_type_name" = 'Solid Tissue Normal'
    AND "gene_type"        = 'protein_coding'
GROUP BY
    "gene_name"
HAVING
    COUNT(*) > 1                     -- ensure variance is computable
ORDER BY
    "var_fpkm_uq" DESC NULLS LAST,   -- highest variance first
    "gene_name"
LIMIT 5;