WITH hom_ref_single_alt AS (
    SELECT
        c.value:"name"::string AS sample_id
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" v
         , LATERAL FLATTEN(input => v."call") c          -- one row per sample per variant
    WHERE ARRAY_SIZE(v."alternate_bases") = 1            -- exactly one alternate allele
      AND c.value:"genotype"[0]::int = 0                 -- first allele is reference
      AND c.value:"genotype"[1]::int = 0                 -- second allele is reference
)
SELECT
    sample_id,
    COUNT(*) AS positions_with_single_alt_hom_ref
FROM hom_ref_single_alt
GROUP BY sample_id
ORDER BY positions_with_single_alt_hom_ref DESC NULLS LAST, sample_id
LIMIT 10;