SELECT
  "sample",
  "hom_ref_sites"
FROM (
  SELECT
    c.value:"name"::STRING  AS "sample",
    COUNT(*)                AS "hom_ref_sites"
  FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" t,
       LATERAL FLATTEN(input => t."call") c
  WHERE ARRAY_SIZE(t."alternate_bases") = 1              -- exactly one ALT allele
    AND c.value:"genotype"[0]::NUMBER = 0                -- first allele  = reference
    AND c.value:"genotype"[1]::NUMBER = 0                -- second allele = reference
  GROUP BY "sample"
)
ORDER BY "hom_ref_sites" DESC NULLS LAST
LIMIT 10;