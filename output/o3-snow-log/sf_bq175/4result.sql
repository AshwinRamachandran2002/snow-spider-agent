/*  Chromosome-1 cytobands in the TCGA-KICH cohort that
    rank within the top 11 for
      – amplifications  (max_copy_number ≥ 4)
      – standard gains (max_copy_number  = 3)
      – heterozygous deletions (max_copy_number = 1)              */

WITH band_stats AS (
  SELECT
    b."cytoband_name",
    /* count of events by CNV category */
    SUM(CASE WHEN g."max_copy_number" >= 4 THEN 1 ELSE 0 END) AS "amplification_cnt",
    SUM(CASE WHEN g."max_copy_number"  = 3 THEN 1 ELSE 0 END) AS "gain_cnt",
    SUM(CASE WHEN g."max_copy_number"  = 1 THEN 1 ELSE 0 END) AS "het_del_cnt"
  FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_GENE_LEVEL_HG38_GDC_R36 g
  JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38 b
    ON g."chromosome" = b."chromosome"          -- both hold values like 'chr1'
   AND g."start_pos"  <= b."hg38_stop"
   AND g."end_pos"    >= b."hg38_start"
  WHERE g."project_short_name" = 'TCGA-KICH'    -- kidney chromophobe cohort
    AND g."chromosome"         = 'chr1'         -- chromosome 1 only
  GROUP BY b."cytoband_name"
),
ranked AS (
  SELECT
    s.*,
    DENSE_RANK() OVER (ORDER BY s."amplification_cnt" DESC NULLS LAST) AS "amplification_rank",
    DENSE_RANK() OVER (ORDER BY s."gain_cnt"          DESC NULLS LAST) AS "gain_rank",
    DENSE_RANK() OVER (ORDER BY s."het_del_cnt"       DESC NULLS LAST) AS "het_del_rank"
  FROM band_stats s
)
SELECT
  r."cytoband_name",
  r."amplification_cnt",
  r."gain_cnt",
  r."het_del_cnt",
  r."amplification_rank",
  r."gain_rank",
  r."het_del_rank"
FROM ranked r
WHERE r."amplification_rank" <= 11
  AND r."gain_rank"          <= 11
  AND r."het_del_rank"       <= 11
ORDER BY r."cytoband_name";