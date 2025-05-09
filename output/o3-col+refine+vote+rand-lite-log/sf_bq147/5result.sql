/* TCGA-BRCA cases that
   1) appear in the hg38 RNA-Seq release R35,
   2) are protein-coding entries,
   3) have ≥2 distinct RNA-Seq sample types
      AND at least one of those types is “Solid Tissue Normal”            */

SELECT
    r."case_barcode",
    COUNT(DISTINCT r."sample_type_name") AS "num_sample_types"
FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35 AS r
WHERE r."project_short_name" = 'TCGA-BRCA'
  AND r."gene_type"          = 'protein_coding'
GROUP BY r."case_barcode"
HAVING COUNT(DISTINCT r."sample_type_name") > 1
   AND SUM(CASE
             WHEN r."sample_type_name" ILIKE '%Solid%Tissue%Normal%'
             THEN 1 ELSE 0
           END) > 0
ORDER BY "num_sample_types" DESC NULLS LAST;