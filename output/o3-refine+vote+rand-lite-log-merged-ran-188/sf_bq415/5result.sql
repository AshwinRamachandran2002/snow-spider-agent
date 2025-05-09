SELECT
       c.value:"name"::string                           AS "Sample_ID",
       COUNT(*)                                         AS "Homozygous_Ref_Positions"
FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220"  v,
     LATERAL FLATTEN( input => v."call" )               c            -- one row per sample / call
WHERE ARRAY_SIZE( v."alternate_bases" )      = 1                     -- exactly one ALT allele at this locus
  AND ARRAY_SIZE( c.value:"genotype" )       = 2                     -- diploid call present
  AND c.value:"genotype"[0]::int             = 0                     -- first allele is reference
  AND c.value:"genotype"[1]::int             = 0                     -- second allele is reference
GROUP BY c.value:"name"::string
ORDER BY "Homozygous_Ref_Positions" DESC NULLS LAST,
         "Sample_ID"
LIMIT 10;