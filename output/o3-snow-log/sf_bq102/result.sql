/* C → T missense BRCA1 variants (chr17) in gnomAD v2.1.1 */
SELECT DISTINCT
       "start_position"
FROM  (

        /* ------------ v2.1.1 EXOMES chr17 ------------ */
        SELECT  "start_position"
        FROM   GNOMAD.GNOMAD."V2_1_1_EXOMES__CHR17"
               ,LATERAL FLATTEN(input => "alternate_bases")          ab
               ,LATERAL FLATTEN(input => ab.value:"vep")             vep
        WHERE  "reference_bases"                                = 'C'
          AND  ab.value:"alt"::string                           = 'T'
          AND  LOWER(vep.value:"SYMBOL"::string)                = 'brca1'
          AND  POSITION('missense_variant',
                        vep.value:"Consequence"::string)        > 0

        UNION ALL

        /* ------------ v2.1.1 GENOMES chr17 ------------ */
        SELECT  "start_position"
        FROM   GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17"
               ,LATERAL FLATTEN(input => "alternate_bases")          ab
               ,LATERAL FLATTEN(input => ab.value:"vep")             vep
        WHERE  "reference_bases"                                = 'C'
          AND  ab.value:"alt"::string                           = 'T'
          AND  LOWER(vep.value:"SYMBOL"::string)                = 'brca1'
          AND  POSITION('missense_variant',
                        vep.value:"Consequence"::string)        > 0
      ) AS merged
ORDER BY "start_position";