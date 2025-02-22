-- Task: Using segment-level copy number data from the 'COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23' dataset restricted to 'TCGA-KIRC' samples, merge these segments with the cytogenetic band definitions in 'CytoBands_hg38' to identify each sample’s maximum copy number per cytoband, then present these results sorted by chromosome and cytoband. Show only the first 100 results.
WITH copy AS (
  SELECT 
    "case_barcode", 
    "chromosome", 
    "start_pos", 
    "end_pos", 
    MAX("copy_number") AS "copy_number"
  FROM 
    "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" 
  WHERE  
    "project_short_name" = 'TCGA-KIRC'
  GROUP BY 
    "case_barcode", 
    "chromosome", 
    "start_pos", 
    "end_pos"
),
cytob AS (
  SELECT 
    "chromosome", 
    "cytoband_name", 
    "hg38_start", 
    "hg38_stop"
  FROM 
    "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
),
joined AS (
  SELECT 
    cytob."chromosome", 
    cytob."cytoband_name", 
    cytob."hg38_start", 
    cytob."hg38_stop",
    copy."case_barcode",
    copy."copy_number"  
  FROM 
    copy
  LEFT JOIN cytob
    ON cytob."chromosome" = copy."chromosome" 
  WHERE 
    (cytob."hg38_start" >= copy."start_pos" AND copy."end_pos" >= cytob."hg38_start")
    OR (copy."start_pos" >= cytob."hg38_start" AND copy."start_pos" <= cytob."hg38_stop")
),
cbands AS (
  SELECT 
    "chromosome", 
    "cytoband_name", 
    "hg38_start", 
    "hg38_stop", 
    "case_barcode",
    MAX("copy_number") AS "copy_number"
  FROM 
    joined
  GROUP BY 
    "chromosome", 
    "cytoband_name", 
    "hg38_start", 
    "hg38_stop", 
    "case_barcode"
)
SELECT 
  "chromosome", 
  "cytoband_name",
  "case_barcode",
  "copy_number"
FROM 
  cbands
ORDER BY 
  "chromosome", 
  "cytoband_name"
LIMIT 100;