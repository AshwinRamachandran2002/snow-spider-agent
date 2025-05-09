SELECT DISTINCT v."start_position"
FROM (
        SELECT "reference_name",
               "start_position",
               "reference_bases",
               "alternate_bases"
        FROM   GNOMAD.GNOMAD."V2_1_1_EXOMES__CHR17"
        UNION ALL
        SELECT "reference_name",
               "start_position",
               "reference_bases",
               "alternate_bases"
        FROM   GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17"
     ) v,
     LATERAL FLATTEN(input => v."alternate_bases")              alt,
     LATERAL FLATTEN(input => alt.value:"vep")                  vep
WHERE  v."reference_name"         = '17'
  AND  v."reference_bases"        = 'C'
  AND  alt.value:"alt"::string     = 'T'
  AND  vep.value:"SYMBOL"::string  = 'BRCA1'
  AND  vep.value:"Consequence"::string ILIKE '%missense_variant%'
ORDER BY v."start_position";