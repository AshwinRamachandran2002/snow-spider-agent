SELECT
    "gene_name",
    VAR_SAMP("fpkm_uq_unstranded") AS "var_fpkm_uq"
FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R40
WHERE "project_short_name" = 'TCGA-BRCA'
  AND "sample_type_name" ILIKE '%Solid%Tissue%Normal%'   -- only solid-normal samples
  AND "gene_type" = 'protein_coding'                    -- restrict to protein-coding genes
  AND "fpkm_uq_unstranded" IS NOT NULL                  -- exclude missing expression values
  AND "gene_name" IS NOT NULL                           -- exclude rows lacking a gene name
GROUP BY "gene_name"
ORDER BY "var_fpkm_uq" DESC NULLS LAST                  -- highest variance first
LIMIT 5;