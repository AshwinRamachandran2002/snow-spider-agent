SELECT
  c.value:"name"::STRING                          AS "sample",
  COUNT(*)                                        AS "hom_ref_pos_cnt"
FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" t,
     LATERAL FLATTEN(input => t."call") c
WHERE ARRAY_SIZE(t."alternate_bases") = 1
  AND c.value:"genotype"[0]::NUMBER = 0
  AND c.value:"genotype"[1]::NUMBER = 0
GROUP BY "sample"
ORDER BY "hom_ref_pos_cnt" DESC NULLS LAST,
         "sample"
LIMIT 10;