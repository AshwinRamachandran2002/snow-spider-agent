SELECT DISTINCT
       u."start_position"
FROM (
        SELECT "start_position",
               "reference_bases",
               "alternate_bases"
        FROM   "GNOMAD"."GNOMAD"."V2_1_1_EXOMES__CHR17"
        UNION ALL
        SELECT "start_position",
               "reference_bases",
               "alternate_bases"
        FROM   "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"
     )                       AS u,
     LATERAL FLATTEN(INPUT => u."alternate_bases")         AS alt,      -- one row per ALT record
     LATERAL FLATTEN(INPUT => alt.VALUE:"vep")             AS vep       -- one row per VEP annotation
WHERE u."reference_bases"              = 'C'                           -- reference base
  AND alt.VALUE:"alt"::STRING          = 'T'                           -- alternate base
  AND vep.VALUE:"SYMBOL"::STRING       = 'BRCA1'                       -- gene
  AND POSITION('missense_variant',
               vep.VALUE:"Consequence"::STRING) > 0;                   -- missense consequence