WITH hom_ref_sites AS (
    SELECT
        c.value::VARIANT:"name"::STRING AS "sample"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" t,
         LATERAL FLATTEN(input => t."call") c
    WHERE ARRAY_SIZE(t."alternate_bases") = 1            -- exactly one ALT allele in the record
      AND c.value::VARIANT:"genotype"[0] = 0              -- homozygous reference 0/0
      AND c.value::VARIANT:"genotype"[1] = 0
)
SELECT
    "sample",
    COUNT(*) AS "hom_ref_single_alt_sites"
FROM hom_ref_sites
GROUP BY "sample"
ORDER BY "hom_ref_single_alt_sites" DESC NULLS LAST
LIMIT 10;