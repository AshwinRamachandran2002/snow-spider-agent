SELECT b."case_barcode",
       LISTAGG(DISTINCT b."sample_type", ';') AS "sample_types"
FROM "TCGA"."TCGA_VERSIONED"."BIOSPECIMEN_GDC_2017_02" b
JOIN "TCGA"."TCGA_VERSIONED"."RNASEQ_HG38_GDC_R28" r
  ON b."case_barcode" = r."case_barcode" AND b."sample_barcode" = r."sample_barcode"
WHERE b."project_short_name" = 'TCGA-BRCA'
  AND r."project_short_name" = 'TCGA-BRCA'
  AND r."gene_type" = 'protein_coding'
  AND b."sample_type" IN ('01', '06', '10', '11')
GROUP BY b."case_barcode"
HAVING COUNT(DISTINCT CASE WHEN b."sample_type" = '11' THEN 1 END) > 0
   AND COUNT(DISTINCT CASE WHEN b."sample_type" != '11' THEN 1 END) > 0;