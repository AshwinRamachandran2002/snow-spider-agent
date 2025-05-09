SELECT "case_barcode",
       LISTAGG(DISTINCT "sample_type_name", ';') AS "sample_types"
FROM "TCGA"."TCGA_VERSIONED"."RNASEQ_HG38_GDC_R28"
WHERE "project_short_name" = 'TCGA-BRCA' AND "gene_type" = 'protein_coding'
GROUP BY "case_barcode"
HAVING COUNT(DISTINCT CASE WHEN "sample_type_name" = 'Solid Tissue Normal' THEN 1 END) > 0
   AND COUNT(DISTINCT CASE WHEN "sample_type_name" != 'Solid Tissue Normal' THEN 1 END) > 0;