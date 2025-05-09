WITH brca_cases_with_normals AS (
    SELECT DISTINCT "case_barcode"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name"   = 'Solid Tissue Normal'
)
SELECT
    r."gene_name"                                            AS gene_symbol,
    ROUND(VAR_SAMP(r."HTSeq__FPKM_UQ"), 4)                   AS variance_fpkm_uq_unstranded
FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28 r
JOIN brca_cases_with_normals b
  ON r."case_barcode" = b."case_barcode"
WHERE r."sample_type_name" = 'Solid Tissue Normal'
  AND r."gene_type"        = 'protein_coding'
GROUP BY r."gene_name"
ORDER BY variance_fpkm_uq_unstranded DESC NULLS LAST,
         gene_symbol
LIMIT 5;