-- Identify TCGA-BRCA cases that have protein-coding RNA-Seq records
-- for more than one tissue type *and* include at least one
-- “Solid Tissue Normal” sample
WITH brca_pc AS (
    SELECT 
        "case_barcode",
        "sample_type_name"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_type"         = 'protein_coding'
), multi_tissue AS (
    SELECT 
        "case_barcode"
    FROM brca_pc
    GROUP BY "case_barcode"
    HAVING COUNT(DISTINCT "sample_type_name") > 1               -- multiple tissue types
       AND SUM(CASE                                             -- includes Solid Tissue Normal
                 WHEN "sample_type_name" ILIKE '%Solid%Tissue%Normal%' 
                 THEN 1 ELSE 0 
               END) > 0
)
SELECT DISTINCT
       "case_barcode"
FROM   multi_tissue
ORDER BY "case_barcode";