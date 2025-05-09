SELECT
  c.value:"name"::string                                     AS "Sample",
  COUNT(*)                                                   AS "Hom_Ref_Single_ALT_Count"
FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" v,
     LATERAL FLATTEN(input => v."call")                      c
WHERE ARRAY_SIZE(v."alternate_bases") = 1                     -- exactly one alternate allele
  AND c.value:"genotype"[0]::int = 0                          -- first allele is reference
  AND c.value:"genotype"[1]::int = 0                          -- second allele is reference
GROUP BY "Sample"
ORDER BY "Hom_Ref_Single_ALT_Count" DESC NULLS LAST
LIMIT 10;