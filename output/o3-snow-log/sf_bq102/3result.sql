/*  Start positions of BRCA1 missense C>T variants on chromosome 17
    in gnomAD v2.1.1 (exomes + genomes) */
SELECT  DISTINCT t."start_position"
FROM   (
          /* v2.1.1 – Exomes chr17 */
          SELECT "start_position",
                 "reference_name",
                 "reference_bases",
                 "alternate_bases"
          FROM   GNOMAD.GNOMAD."V2_1_1_EXOMES__CHR17"

          UNION ALL

          /* v2.1.1 – Genomes chr17 */
          SELECT "start_position",
                 "reference_name",
                 "reference_bases",
                 "alternate_bases"
          FROM   GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17"
       ) t
        ,LATERAL FLATTEN (INPUT => t."alternate_bases")            ab     /* one JSON block per allele */
        ,LATERAL FLATTEN (INPUT => ab.value:"vep")                  v      /* one VEP annotation row   */
WHERE  t."reference_name"      = '17'               -- chromosome
  AND  t."reference_bases"     = 'C'                -- reference base
  AND  ab.value:"alt"::STRING  = 'T'                -- alternate base
  AND  ( v.value:"Consequence"::STRING ILIKE '%missense_variant%' )  -- missense
  AND  ( v.value:"SYMBOL"::STRING = 'BRCA1'                             -- BRCA1 by gene symbol
         OR v.value:"Gene"::STRING = 'ENSG00000012048' )               -- or Ensembl ID
ORDER BY t."start_position";