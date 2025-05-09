SELECT
    sample_id,
    COUNT(*) AS hom_ref_positions
FROM (
    SELECT
        call_elem.value:"name"::string AS sample_id
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" v,
         LATERAL FLATTEN(input => v."call") call_elem
    WHERE  ARRAY_SIZE(v."alternate_bases") = 1                          -- exactly one alternate allele
       AND ARRAY_SIZE(call_elem.value:"genotype") = 2                  -- diploid genotype present
       AND call_elem.value:"genotype"[0]::int = 0                      -- homozygous reference (0/0)
       AND call_elem.value:"genotype"[1]::int = 0
)
GROUP BY sample_id
ORDER BY hom_ref_positions DESC NULLS LAST
LIMIT 10;