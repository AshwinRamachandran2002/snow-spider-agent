-- Task: Retrieve the maximum copy number per segment for the TCGA-LAML study
SELECT 
  "case_barcode", 
  "chromosome", 
  "start_pos", 
  "end_pos", 
  MAX("copy_number") AS "copy_number"
FROM 
  "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
WHERE 
  "project_short_name" = 'TCGA-LAML'
GROUP BY 
  "case_barcode", 
  "chromosome", 
  "start_pos", 
  "end_pos"
LIMIT 100;