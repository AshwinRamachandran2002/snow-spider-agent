SELECT
    sample_id,
    COUNT(*) AS hom_ref_single_alt_count
FROM (
    SELECT
        f.value::STRING AS sample_id
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v,
         LATERAL FLATTEN(input => v."hom_ref_call") f
    WHERE ARRAY_SIZE(v."alternate_bases") = 1        -- exactly one alternate allele
      AND f.value IS NOT NULL                        -- valid sample id
) AS t
GROUP BY sample_id
ORDER BY hom_ref_single_alt_count DESC NULLS LAST
LIMIT 10;