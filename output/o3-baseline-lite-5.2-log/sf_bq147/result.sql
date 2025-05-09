SELECT
    "case_barcode"
FROM (
    /* keep only BRCA protein‑coding rows and one record per case‑sampleType */
    SELECT DISTINCT
        "case_barcode",
        "sample_type_name"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_type"          = 'protein_coding'
)
GROUP BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") > 1                     -- multiple tissue types
   AND MAX(CASE WHEN "sample_type_name" = 'Solid Tissue Normal'   -- includes STN
                THEN 1 ELSE 0 END) = 1;