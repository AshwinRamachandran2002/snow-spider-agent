--  TCGA-BRCA RNA-Seq (hg38 r35): cases with protein-coding reads that include
--  more than one tissue type AND at least one “Solid Tissue Normal” sample
SELECT
    "case_barcode"
FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35
WHERE "project_short_name" = 'TCGA-BRCA'
  AND "gene_type"        = 'protein_coding'
GROUP BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") > 1
   AND SUM(CASE WHEN "sample_type_name" ILIKE '%Solid%Tissue%Normal%' THEN 1 ELSE 0 END) > 0
ORDER BY "case_barcode";