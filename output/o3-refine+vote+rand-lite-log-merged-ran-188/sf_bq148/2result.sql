WITH "solid_cases" AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name" = 'Solid Tissue Normal'
),
"solid_samples" AS (
    SELECT 
        r."gene_name",
        r."HTSeq__FPKM_UQ" AS "fpkm_uq"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28" r
    JOIN "solid_cases" c
      ON r."case_barcode" = c."case_barcode"
    WHERE r."project_short_name" = 'TCGA-BRCA'
      AND r."sample_type_name" = 'Solid Tissue Normal'
      AND r."gene_type" = 'protein_coding'
      AND r."HTSeq__FPKM_UQ" IS NOT NULL
)
SELECT 
    "gene_name",
    VAR_SAMP("fpkm_uq") AS "variance_fpkm_uq"
FROM "solid_samples"
GROUP BY "gene_name"
HAVING COUNT(*) > 1
ORDER BY "variance_fpkm_uq" DESC NULLS LAST, "gene_name"
LIMIT 5;