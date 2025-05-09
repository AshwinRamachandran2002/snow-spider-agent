SELECT
  c.value:"name"::STRING                              AS "sample",
  COUNT(*)                                            AS "hom_ref_single_alt_sites"
FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" AS t,
     LATERAL FLATTEN(input => t."call")               AS c
WHERE ARRAY_SIZE(t."alternate_bases") = 1                      -- exactly one ALT allele
  AND c.value:"genotype"[0]::INT = 0                           -- homozygous reference (0/0)
  AND c.value:"genotype"[1]::INT = 0
GROUP BY 1
HAVING "sample" IS NOT NULL
ORDER BY "hom_ref_single_alt_sites" DESC NULLS LAST
LIMIT 10;