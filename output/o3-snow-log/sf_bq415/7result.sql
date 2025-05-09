WITH hom_ref_variants AS (
    -- 1.  Keep only variant records that have exactly one alternate allele
    -- 2.  Expand the per-sample calls
    -- 3.  Keep the calls whose genotype is homozygous reference (0/0)
    SELECT
        c.value:"name"::STRING  AS sample_id
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220"  v,
         LATERAL FLATTEN(input => v."call") AS c
    WHERE ARRAY_SIZE(v."alternate_bases") = 1
      AND c.value:"genotype"[0]::INT = 0
      AND c.value:"genotype"[1]::INT = 0
)

SELECT
    sample_id,
    COUNT(*) AS hom_ref_single_alt_sites
FROM hom_ref_variants
GROUP BY sample_id
ORDER BY hom_ref_single_alt_sites DESC NULLS LAST
LIMIT 10;