SELECT
  f.value:"name"::STRING  AS "Sample_ID",
  COUNT(*)               AS "HomRef_SingleAlt_Count"
FROM "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_VARIANTS_20150220" v,
     LATERAL FLATTEN(INPUT => v."call") f
WHERE ARRAY_SIZE(v."alternate_bases") = 1                       -- exactly one ALT allele
  AND f.value:"genotype"[0]::NUMBER = 0                         -- homozygous reference (0/0)
  AND f.value:"genotype"[1]::NUMBER = 0
GROUP BY "Sample_ID"
ORDER BY "HomRef_SingleAlt_Count" DESC NULLS LAST
LIMIT 10;