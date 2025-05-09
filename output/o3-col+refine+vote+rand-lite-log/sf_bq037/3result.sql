WITH total AS (
  SELECT COUNT(*) AS "total_cnt"
  FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
  WHERE "partition_date_please_ignore" = '2015-02-20'
)
SELECT
  v."reference_bases",
  MIN(v."start_position") AS "min_start",
  MAX(v."start_position") AS "max_start",
  COUNT(*)               AS "base_count",
  ROUND(COUNT(*) / t."total_cnt"::FLOAT, 4) AS "proportion"
FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v,
     total t
WHERE v."partition_date_please_ignore" = '2015-02-20'
  AND v."reference_bases" IN ('AT', 'TA')
GROUP BY v."reference_bases", t."total_cnt"
ORDER BY v."reference_bases";