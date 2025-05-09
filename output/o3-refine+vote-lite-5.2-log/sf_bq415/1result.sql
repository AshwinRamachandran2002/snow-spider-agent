SELECT
    f.value::string                                   AS "Sample",
    COUNT(*)                                          AS "Num_Positions"
FROM
    HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"  v,
    LATERAL FLATTEN(input => v."hom_ref_call") f
WHERE
      v."alternate_bases" IS NOT NULL
  AND ARRAY_SIZE(v."alternate_bases") = 1            -- exactly one alternate allele
GROUP BY
    f.value::string
ORDER BY
    "Num_Positions" DESC NULLS LAST,
    "Sample"
LIMIT 10;