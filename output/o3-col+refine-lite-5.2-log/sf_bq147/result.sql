-- Identify TCGA‑BRCA cases that have protein‑coding RNA‑seq data
-- from at least two tissue types, one of which is “Solid Tissue Normal”
WITH brca_pc AS (
    SELECT DISTINCT
           "case_barcode",
           "sample_type_name"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_type" = 'protein_coding'
)

SELECT
       "case_barcode"
FROM brca_pc
GROUP BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") >= 2
   AND MAX(CASE WHEN "sample_type_name" = 'Solid Tissue Normal' THEN 1 ELSE 0 END) = 1
ORDER BY "case_barcode";