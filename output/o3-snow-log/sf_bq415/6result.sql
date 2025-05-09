WITH hom_ref_per_sample AS (
    /* keep only variants that have exactly one alternate allele,
       then expand the list of homozygous-reference samples        */
    SELECT
        hom_ref.value::string            AS "Sample",
        COUNT(*)                         AS "HomRef_SingleAlt_Positions"
    FROM
        HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS._1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220  v,
        LATERAL FLATTEN (input => v."hom_ref_call")                   hom_ref
    WHERE
        ARRAY_SIZE(v."alternate_bases") = 1       -- exactly one ALT allele
        AND hom_ref.value IS NOT NULL             -- valid sample name
    GROUP BY
        hom_ref.value::string
)

SELECT
    "Sample",
    "HomRef_SingleAlt_Positions"
FROM
    hom_ref_per_sample
ORDER BY
    "HomRef_SingleAlt_Positions" DESC NULLS LAST
LIMIT 10;