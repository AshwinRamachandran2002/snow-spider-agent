SELECT
  s.value::string                                   AS "Sample_ID",
  COUNT(*)                                          AS "Hom_Ref_Positions"
FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v,
     LATERAL FLATTEN(input => v."hom_ref_call") s          -- one row per sample that is 0/0 at this site
WHERE ARRAY_SIZE(v."alternate_bases") = 1                  -- keep sites with exactly one alternate allele
GROUP BY s.value::string
ORDER BY "Hom_Ref_Positions" DESC NULLS LAST
LIMIT 10;