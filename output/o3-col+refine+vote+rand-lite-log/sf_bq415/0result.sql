SELECT
  c.value:"name"::STRING                      AS "sample",
  COUNT(*)                                    AS "hom_ref_single_alt_sites"
FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220"  t,
     LATERAL FLATTEN(input => t."call")       c
WHERE ARRAY_SIZE(t."alternate_bases") = 1                      -- exactly one ALT allele at the site
  AND c.value:"genotype"[0]::INTEGER = 0                       -- first allele is reference
  AND c.value:"genotype"[1]::INTEGER = 0                       -- second allele is reference
GROUP BY "sample"
ORDER BY "hom_ref_single_alt_sites" DESC NULLS LAST
LIMIT 10;