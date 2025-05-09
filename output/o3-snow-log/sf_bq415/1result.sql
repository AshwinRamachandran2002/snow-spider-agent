SELECT 
    c.value:"name"::STRING            AS "Sample_ID",
    COUNT(*)                          AS "Hom_Ref_Positions"
FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220"  v
     ,LATERAL FLATTEN(input => v."call")                                    c          -- one row per sample-specific call
WHERE ARRAY_SIZE(v."alternate_bases") = 1                                   -- exactly one ALT allele
  AND c.value:"genotype"[0]::INT = 0                                        -- first allele is reference
  AND c.value:"genotype"[1]::INT = 0                                        -- second allele is reference
GROUP BY c.value:"name"::STRING
ORDER BY "Hom_Ref_Positions" DESC NULLS LAST
LIMIT 10;