SELECT
    hom_ref_sample.value::string        AS "SAMPLE_ID",
    COUNT(*)                            AS "NUM_HOM_REF_SITES"
FROM
    HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" AS v,
    LATERAL FLATTEN( INPUT => v."hom_ref_call" )                       AS hom_ref_sample
WHERE
    ARRAY_SIZE( v."alternate_bases" ) = 1                              -- exactly one ALT allele
GROUP BY
    hom_ref_sample.value::string
ORDER BY
    "NUM_HOM_REF_SITES" DESC NULLS LAST,
    "SAMPLE_ID"
LIMIT 10;