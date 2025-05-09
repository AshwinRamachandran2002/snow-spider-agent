SELECT
  f.value::STRING AS "sample_id",
  COUNT(*)        AS "homozygous_reference_single_alt_positions"
FROM
  "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v,
  LATERAL FLATTEN(input => v."hom_ref_call") f
WHERE
  ARRAY_SIZE(v."alternate_bases") = 1
GROUP BY
  f.value::STRING
ORDER BY
  "homozygous_reference_single_alt_positions" DESC NULLS LAST,
  "sample_id" ASC
LIMIT 10;