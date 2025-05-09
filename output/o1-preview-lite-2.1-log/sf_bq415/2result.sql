SELECT
  f.value:"name"::STRING AS "sample_id",
  COUNT(*) AS num_hom_ref_genotypes
FROM 
  "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_VARIANTS_20150220" AS t,
  LATERAL FLATTEN(input => t."call") AS f
WHERE 
  f.value:"genotype" = ARRAY_CONSTRUCT(0, 0)
GROUP BY "sample_id"
ORDER BY num_hom_ref_genotypes DESC NULLS LAST
LIMIT 10;