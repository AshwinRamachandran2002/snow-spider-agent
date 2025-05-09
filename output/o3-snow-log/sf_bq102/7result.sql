SELECT DISTINCT
       t."start_position"
FROM (
        /* gnomAD v2.1.1  –  keep only SNVs with ref base C before flattening */
        SELECT  "start_position",
                "alternate_bases"
        FROM    "GNOMAD"."GNOMAD"."V2_1_1_EXOMES__CHR17"
        WHERE   "variant_type" = 'snv'
          AND   "reference_bases" = 'C'

        UNION ALL

        SELECT  "start_position",
                "alternate_bases"
        FROM    "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"
        WHERE   "variant_type" = 'snv'
          AND   "reference_bases" = 'C'
     )                           AS t
     , LATERAL FLATTEN( INPUT => t."alternate_bases" )  AS ab
     , LATERAL FLATTEN( INPUT => ab.value:"vep" )       AS vep
WHERE  ab.value:"alt"::string              = 'T'                 -- alt base T
  AND  vep.value:"SYMBOL"::string          = 'BRCA1'             -- BRCA1 gene
  AND  LOWER(vep.value:"Consequence"::string)  LIKE '%missense_variant%'  -- missense
ORDER BY
       t."start_position";