WITH brca_norm_cases AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name" = 'Solid Tissue Normal'
),
solid_tissue_normal AS (
    SELECT
        "gene_name",
        "HTSeq__FPKM_UQ"      AS fpkm_uq_unstranded
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name"   = 'Solid Tissue Normal'
      AND "case_barcode"       IN (SELECT "case_barcode" FROM brca_norm_cases)
      AND "gene_type"          = 'protein_coding'
      AND "HTSeq__FPKM_UQ" IS NOT NULL
)
SELECT
    "gene_name",
    VAR_SAMP(fpkm_uq_unstranded) AS expression_variance
FROM solid_tissue_normal
GROUP BY "gene_name"
ORDER BY expression_variance DESC NULLS LAST
LIMIT 5;