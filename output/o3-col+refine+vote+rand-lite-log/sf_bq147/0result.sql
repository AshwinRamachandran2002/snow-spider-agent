/* Identify TCGA-BRCA cases (hg38 RNA-Seq release R35) that:
   1) are annotated as protein-coding,
   2) have multiple distinct RNA-Seq tissue types,
   3) include at least one “Solid Tissue Normal” sample. */

SELECT
  "case_barcode"
FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
WHERE "project_short_name" = 'TCGA-BRCA'
  AND "gene_type"           = 'protein_coding'
GROUP BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") > 1          -- multiple tissue types
   AND SUM(CASE WHEN "sample_type_name" ILIKE '%Solid%Tissue%Normal%' THEN 1 ELSE 0 END) > 0
ORDER BY "case_barcode";