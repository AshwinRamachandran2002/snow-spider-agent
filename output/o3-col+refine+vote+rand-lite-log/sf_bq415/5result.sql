SELECT
       c.value:"name"::STRING  AS "sample",
       COUNT(*)                AS "hom_ref_single_alt_sites"
FROM   "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_VARIANTS_20150220" v,
       LATERAL FLATTEN(INPUT => v."call") c
WHERE  ARRAY_SIZE(v."alternate_bases") = 1         -- variant has exactly one ALT allele
  AND  c.value:"genotype"[0]::NUMBER = 0           -- allele 1 is reference
  AND  c.value:"genotype"[1]::NUMBER = 0           -- allele 2 is reference
GROUP  BY "sample"
ORDER  BY "hom_ref_single_alt_sites" DESC NULLS LAST
LIMIT 10;