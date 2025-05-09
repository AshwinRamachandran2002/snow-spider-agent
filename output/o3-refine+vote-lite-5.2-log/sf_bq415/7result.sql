/* top 10 samples with the most sites that
   1) have exactly one alternate allele, and
   2) are homozygous reference (genotype 0/0) for that sample            */

WITH one_alt_variant AS (   -- keep only biallelic (1‑ALT) variant rows
    SELECT
        v."hom_ref_call"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v
    WHERE ARRAY_SIZE(v."alternate_bases") = 1          -- exactly one ALT allele
)
SELECT
    hom_ref_sample.value::string          AS "Sample",
    COUNT(*)                              AS "Hom_Ref_Site_Count"
FROM one_alt_variant,
     LATERAL FLATTEN(input => one_alt_variant."hom_ref_call") AS hom_ref_sample
GROUP BY hom_ref_sample.value
ORDER BY "Hom_Ref_Site_Count" DESC NULLS LAST, "Sample"
LIMIT 10;