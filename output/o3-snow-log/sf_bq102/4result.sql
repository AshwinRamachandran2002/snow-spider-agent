WITH combined AS (
    SELECT 
        "reference_name",
        "start_position",
        "reference_bases",
        "alternate_bases"
    FROM GNOMAD.GNOMAD."V2_1_1_EXOMES__CHR17"

    UNION ALL

    SELECT 
        "reference_name",
        "start_position",
        "reference_bases",
        "alternate_bases"
    FROM GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17"
)

SELECT DISTINCT 
       c."start_position"
FROM combined                         AS c,
     LATERAL FLATTEN(INPUT => c."alternate_bases")   AS alt,
     LATERAL FLATTEN(INPUT => alt.value:"vep")        AS vep
WHERE c."reference_name"      = '17'
  AND c."reference_bases"     = 'C'
  AND alt.value:"alt"::string = 'T'
  AND vep.value:"SYMBOL"::string      = 'BRCA1'
  AND vep.value:"Consequence"::string ILIKE '%missense_variant%'
ORDER BY c."start_position";