SELECT
    "case_barcode" AS case_id,
    ARRAY_TO_STRING(ARRAY_AGG(DISTINCT "sample_type_name"), '; ') AS tissue_types
FROM "TCGA"."TCGA_VERSIONED"."RNASEQ_HG38_GDC_R35"
WHERE "project_short_name" = 'TCGA-BRCA'
  AND "gene_type" = 'protein_coding'
GROUP BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") > 1
   AND SUM(CASE WHEN "sample_type_name" = 'Solid Tissue Normal' THEN 1 ELSE 0 END) > 0
ORDER BY "case_barcode";