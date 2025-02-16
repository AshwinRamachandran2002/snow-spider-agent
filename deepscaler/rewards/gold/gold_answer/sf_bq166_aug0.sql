-- Task: Using segment-level copy number data from the "COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" table in the "TCGA_MITELMAN"."TCGA_VERSIONED" schema, restricted to samples where "project_short_name" is 'TCGA-KIRC', select "case_barcode", "chromosome", "start_pos", "end_pos", and compute the maximum "copy_number" per segment (grouped by "case_barcode", "chromosome", "start_pos", "end_pos"). Then, retrieve cytogenetic band definitions from the "CYTOBANDS_HG38" table in the "TCGA_MITELMAN"."PROD" schema, selecting "chromosome", "cytoband_name", "hg38_start", and "hg38_stop". Next, join these two datasets on overlapping genomic coordinates (where segments and cytobands on the same chromosome overlap in genomic position) to identify each sample's maximum copy number per cytoband, grouping by "chromosome", "cytoband_name", "hg38_start", "hg38_stop", and "case_barcode". Classify these maximum copy numbers per cytoband for each sample into categories: amplifications (copy_number > 3), gains (copy_number = 3), homozygous deletions (copy_number = 0), heterozygous deletions (copy_number = 1), and normal (copy_number = 2). Then, for each cytoband, calculate the total number of cases falling into each category, and compute the frequency (as a percentage) of each category by dividing by the total number of distinct cases. Finally, present these frequencies as percentages, including the total number of cases, and sort the results by "chromosome" and "cytoband_name".

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
total_cases AS (
  SELECT COUNT(DISTINCT "case_barcode") AS "total"
  FROM copy 
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
),
aberrations AS (
  SELECT
    "chromosome",
    "cytoband_name",
    -- Amplifications: copy_number > 3
    SUM( CASE WHEN "copy_number" > 3 THEN 1 ELSE 0 END ) AS "total_amp",
    -- Gains: copy_number = 3
    SUM( CASE WHEN "copy_number" = 3 THEN 1 ELSE 0 END ) AS "total_gain",
    -- Homozygous deletions: copy_number = 0
    SUM( CASE WHEN "copy_number" = 0 THEN 1 ELSE 0 END ) AS "total_homodel",
    -- Heterozygous deletions: copy_number = 1
    SUM( CASE WHEN "copy_number" = 1 THEN 1 ELSE 0 END ) AS "total_heterodel",
    -- Normal: copy_number = 2
    SUM( CASE WHEN "copy_number" = 2 THEN 1 ELSE 0 END ) AS "total_normal"
  FROM 
    cbands
  GROUP BY 
    "chromosome", 
    "cytoband_name"
)
SELECT 
  aberrations."chromosome", 
  aberrations."cytoband_name",
  total_cases."total",  
  100 * aberrations."total_amp" / total_cases."total" AS "freq_amp", 
  100 * aberrations."total_gain" / total_cases."total" AS "freq_gain",
  100 * aberrations."total_homodel" / total_cases."total" AS "freq_homodel", 
  100 * aberrations."total_heterodel" / total_cases."total" AS "freq_heterodel", 
  100 * aberrations."total_normal" / total_cases."total" AS "freq_normal"  
FROM 
  aberrations, 
  total_cases
ORDER BY 
  aberrations."chromosome", 
  aberrations."cytoband_name";