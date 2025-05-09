WITH hom_ref_sites AS (

    /* 1. 1000 Genomes – optimized schema: samples listed in "hom_ref_call" */
    SELECT
        hom.value::STRING          AS sample_name
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v
         , LATERAL FLATTEN( INPUT => v."hom_ref_call") hom
    WHERE ARRAY_SIZE( v."alternate_bases") = 1                 -- exactly one ALT allele
      AND hom.value IS NOT NULL                                -- valid sample entry

    UNION ALL

    /* 2. 1000 Genomes – original phase-3 variants: genotype explicitly 0/0 */
    SELECT
        c.value:"name"::STRING     AS sample_name
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" v
         , LATERAL FLATTEN( INPUT => v."call") c
    WHERE ARRAY_SIZE( v."alternate_bases") = 1                 -- exactly one ALT allele
      AND c.value:"genotype"[0]::INT = 0                       -- homo-ref 1st allele
      AND c.value:"genotype"[1]::INT = 0                       -- homo-ref 2nd allele
)

SELECT
    sample_name,
    COUNT(*) AS homo_ref_single_alt_count
FROM hom_ref_sites
GROUP BY sample_name
ORDER BY homo_ref_single_alt_count DESC NULLS LAST
LIMIT 10;