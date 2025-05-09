WITH total_cases AS (
   SELECT COUNT(DISTINCT "case_barcode") AS "total_cases"
   FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
   WHERE "project_short_name" = 'TCGA-BRCA'
),
cases AS (
   SELECT DISTINCT "case_barcode"
   FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
   WHERE "project_short_name" = 'TCGA-BRCA'
),
cytobands AS (
   SELECT DISTINCT "cytoband_name", "chromosome", "hg38_start", "hg38_stop"
   FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
),
cases_cytobands AS (
   SELECT 
     c."case_barcode",
     cb."cytoband_name",
     cb."chromosome",
     cb."hg38_start",
     cb."hg38_stop"
   FROM cases c CROSS JOIN cytobands cb
),
cnv_segments AS (
   SELECT
     cn."case_barcode",
     cn."chromosome",
     cn."start_pos",
     cn."end_pos",
     cn."copy_number"
   FROM
     "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" cn
   WHERE
     cn."project_short_name" = 'TCGA-BRCA' AND
     cn."copy_number" IS NOT NULL
),
max_copy_number_per_case_cytoband AS (
   SELECT
     cc."case_barcode",
     cc."cytoband_name",
     cc."chromosome",
     cc."hg38_start",
     cc."hg38_stop",
     COALESCE(MAX(cn."copy_number"), 2) AS "max_copy_number"
   FROM
     cases_cytobands cc
   LEFT JOIN
     cnv_segments cn
   ON
     cc."case_barcode" = cn."case_barcode" AND
     cc."chromosome" = cn."chromosome" AND
     cn."start_pos" <= cc."hg38_stop" AND
     cn."end_pos" >= cc."hg38_start"
   GROUP BY
     cc."case_barcode",
     cc."cytoband_name",
     cc."chromosome",
     cc."hg38_start",
     cc."hg38_stop"
),
cnv_classification AS (
   SELECT
     "cytoband_name",
     "hg38_start",
     "hg38_stop",
     "case_barcode",
     CASE
       WHEN "max_copy_number" >= 4 THEN 'amplification'
       WHEN "max_copy_number" = 3 THEN 'gain'
       WHEN "max_copy_number" = 2 THEN 'normal_diploid'
       WHEN "max_copy_number" = 1 THEN 'heterozygous_deletion'
       WHEN "max_copy_number" = 0 THEN 'homozygous_deletion'
       ELSE 'other'
     END AS "cnv_type"
   FROM
     max_copy_number_per_case_cytoband
),
cnv_counts AS (
   SELECT
     "cytoband_name",
     "hg38_start",
     "hg38_stop",
     SUM(CASE WHEN "cnv_type" = 'amplification' THEN 1 ELSE 0 END) AS "amplification_count",
     SUM(CASE WHEN "cnv_type" = 'gain' THEN 1 ELSE 0 END) AS "gain_count",
     SUM(CASE WHEN "cnv_type" = 'normal_diploid' THEN 1 ELSE 0 END) AS "normal_diploid_count",
     SUM(CASE WHEN "cnv_type" = 'heterozygous_deletion' THEN 1 ELSE 0 END) AS "heterozygous_deletion_count",
     SUM(CASE WHEN "cnv_type" = 'homozygous_deletion' THEN 1 ELSE 0 END) AS "homozygous_deletion_count"
   FROM
     cnv_classification
   GROUP BY
     "cytoband_name",
     "hg38_start",
     "hg38_stop"
),
final_output AS (
   SELECT
     c."cytoband_name",
     c."hg38_start",
     c."hg38_stop",
     ROUND(c."homozygous_deletion_count" * 100.0000 / t."total_cases", 4) AS "homozygous_deletion_freq",
     ROUND(c."heterozygous_deletion_count" * 100.0000 / t."total_cases", 4) AS "heterozygous_deletion_freq",
     ROUND(c."normal_diploid_count" * 100.0000 / t."total_cases", 4) AS "normal_diploid_freq",
     ROUND(c."gain_count" * 100.0000 / t."total_cases", 4) AS "gain_freq",
     ROUND(c."amplification_count" * 100.0000 / t."total_cases", 4) AS "amplification_freq"
   FROM
     cnv_counts c, total_cases t
)
SELECT
  "cytoband_name",
  "hg38_start",
  "hg38_stop",
  "homozygous_deletion_freq",
  "heterozygous_deletion_freq",
  "normal_diploid_freq",
  "gain_freq",
  "amplification_freq"
FROM
  final_output
ORDER BY
  "cytoband_name";