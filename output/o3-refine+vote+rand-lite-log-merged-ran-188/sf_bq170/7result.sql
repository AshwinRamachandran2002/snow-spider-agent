/*---------------------------------------------------------------
  CNV frequency per cytoband for TCGA-BRCA cases (GDC Release-23)
----------------------------------------------------------------*/
WITH seg AS (   -- all copy–number segments for BRCA
  SELECT
      "case_barcode",
      "chromosome",
      "start_pos",
      "end_pos",
      "copy_number"
  FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
  WHERE "project_short_name" = 'TCGA-BRCA'
),

cyto AS (       -- cytoband definitions (hg38)
  SELECT
      "chromosome",
      "cytoband_name",
      "hg38_start",
      "hg38_stop"
  FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
),

/* join segments to cytobands & keep positive overlaps */
joined AS (
  SELECT
      s."case_barcode",
      c."cytoband_name",
      c."hg38_start",
      c."hg38_stop",
      s."copy_number",
      /* bp overlap length */
      LEAST(s."end_pos", c."hg38_stop")
        - GREATEST(s."start_pos", c."hg38_start") + 1      AS "ov"
  FROM seg  s
  JOIN cyto c
    ON c."chromosome" = s."chromosome"
  WHERE LEAST(s."end_pos", c."hg38_stop")
        - GREATEST(s."start_pos", c."hg38_start") + 1  > 0
),

/* overlap-weighted copy number per (case, cytoband) */
per_band AS (
  SELECT
      "case_barcode",
      "cytoband_name",
      "hg38_start",
      "hg38_stop",
      ROUND( SUM("ov" * "copy_number")
             / NULLIF(SUM("ov"),0) )                     AS "rounded_cn"
  FROM joined
  GROUP BY
      "case_barcode",
      "cytoband_name",
      "hg38_start",
      "hg38_stop"
),

/* classify rounded copy numbers into CNV types */
classified AS (
  SELECT
      "case_barcode",
      "cytoband_name",
      "hg38_start",
      "hg38_stop",
      "rounded_cn",
      CASE
        WHEN "rounded_cn" = 0 THEN 'homozygous_deletion'
        WHEN "rounded_cn" = 1 THEN 'heterozygous_deletion'
        WHEN "rounded_cn" = 2 THEN 'diploid'
        WHEN "rounded_cn" = 3 THEN 'gain'
        WHEN "rounded_cn" > 3 THEN 'amplification'
      END                                             AS "cnv_type"
  FROM per_band
),

/* total number of BRCA cases in this release */
total_cases AS (
  SELECT COUNT(DISTINCT "case_barcode") AS "n_cases"
  FROM seg
)

/*---------------------------  final frequencies  ---------------*/
SELECT
    c."cytoband_name",
    c."hg38_start",
    c."hg38_stop",
    ROUND(100 * COUNT_IF(c."cnv_type" = 'homozygous_deletion')   / t."n_cases", 2) AS "homozygous_deletion_pct",
    ROUND(100 * COUNT_IF(c."cnv_type" = 'heterozygous_deletion') / t."n_cases", 2) AS "heterozygous_deletion_pct",
    ROUND(100 * COUNT_IF(c."cnv_type" = 'diploid')               / t."n_cases", 2) AS "diploid_pct",
    ROUND(100 * COUNT_IF(c."cnv_type" = 'gain')                  / t."n_cases", 2) AS "gain_pct",
    ROUND(100 * COUNT_IF(c."cnv_type" = 'amplification')         / t."n_cases", 2) AS "amplification_pct"
FROM classified c
CROSS JOIN total_cases t          -- provides the denominator (total cases)
GROUP BY
    c."cytoband_name",
    c."hg38_start",
    c."hg38_stop",
    t."n_cases"
ORDER BY
    c."cytoband_name";