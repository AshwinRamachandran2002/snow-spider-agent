WITH stn_cases AS (
    -- identify TCGA-BRCA cases that have ≥1 Solid Tissue Normal sample
    SELECT DISTINCT SUBSTR("sample_barcode", 1, 12) AS "case_barcode"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R40
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name" = 'Solid Tissue Normal'
),
gene_variance AS (
    -- compute variance of expression (FPKM-UQ) for protein-coding genes
    SELECT
        r."gene_name",
        VAR_SAMP(r."fpkm_uq_unstranded") AS "variance_fpkm_uq"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R40 r
    JOIN stn_cases c
      ON SUBSTR(r."sample_barcode", 1, 12) = c."case_barcode"
    WHERE r."project_short_name" = 'TCGA-BRCA'
      AND r."sample_type_name" = 'Solid Tissue Normal'
      AND r."gene_type" = 'protein_coding'
      AND r."gene_name" IS NOT NULL
      AND r."fpkm_uq_unstranded" IS NOT NULL
    GROUP BY r."gene_name"
)
SELECT
    "gene_name",
    "variance_fpkm_uq"
FROM gene_variance
ORDER BY "variance_fpkm_uq" DESC NULLS LAST
LIMIT 5;