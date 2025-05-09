SELECT 
    "gene_name",
    VAR_SAMP("HTSeq__FPKM_UQ") AS "variance_fpkm_uq"
FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28"
WHERE 
    "project_short_name" = 'TCGA-BRCA'         -- restrict to BRCA project
    AND "sample_type_name" = 'Solid Tissue Normal' -- use Solid Tissue Normal samples only
    AND "gene_type" = 'protein_coding'         -- protein‑coding genes
GROUP BY 
    "gene_name"
ORDER BY 
    "variance_fpkm_uq" DESC NULLS LAST,        -- highest variance first
    "gene_name"
LIMIT 5;