SELECT
    c.value:"name"::STRING  AS "sample_id",
    COUNT(*)                AS "hom_ref_single_alt_sites"
FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" v,
     LATERAL FLATTEN(input => v."call") c
WHERE ARRAY_SIZE(v."alternate_bases") = 1
  AND c.value:"genotype"[0]::NUMBER = 0
  AND c.value:"genotype"[1]::NUMBER = 0
GROUP BY c.value:"name"::STRING
ORDER BY "hom_ref_single_alt_sites" DESC NULLS LAST
LIMIT 10;