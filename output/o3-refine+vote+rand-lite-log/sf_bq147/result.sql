SELECT DISTINCT "case_barcode"
FROM (
    /* keep one row per case & sample‑type after filtering to BRCA protein‑coding genes */
    SELECT DISTINCT 
           "case_barcode",
           "sample_type_name"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_type"        = 'protein_coding'
)
GROUP BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") > 1              -- multiple tissue types
   AND COUNT_IF("sample_type_name" = 'Solid Tissue Normal') > 0  -- includes Solid Tissue Normal
ORDER BY "case_barcode";