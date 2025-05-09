WITH cases_with_stn AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name" = 'Solid Tissue Normal'
), stn_samples AS (
    SELECT
        "gene_name",
        "HTSeq__FPKM_UQ" AS fpkm_uq_unstranded
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name" = 'Solid Tissue Normal'
      AND "gene_type" = 'protein_coding'
      AND "case_barcode" IN (SELECT "case_barcode" FROM cases_with_stn)
)
SELECT
    "gene_name" AS gene_symbol,
    ROUND(VAR_SAMP(fpkm_uq_unstranded), 4) AS variance_fpkm_uq_unstranded
FROM stn_samples
GROUP BY "gene_name"
ORDER BY variance_fpkm_uq_unstranded DESC NULLS LAST, gene_symbol
LIMIT 5;