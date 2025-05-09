WITH union17 AS (
    /*  Coordinates of BRCA1 on GRCh37/hg19: 17:41,196,312-41,277,500           */
    /*  Pre-filter rows to shrink the amount of data we later need to flatten   */
    SELECT 
        "start_position",
        "alternate_bases"
    FROM GNOMAD.GNOMAD."V2_1_1_EXOMES__CHR17"
    WHERE "reference_bases" = 'C'
      AND "start_position" BETWEEN 41196312 AND 41277500

    UNION ALL

    SELECT 
        "start_position",
        "alternate_bases"
    FROM GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17"
    WHERE "reference_bases" = 'C'
      AND "start_position" BETWEEN 41196312 AND 41277500
)

SELECT DISTINCT
       u."start_position"
FROM   union17 u,
       LATERAL FLATTEN(input => u."alternate_bases")          ab,
       LATERAL FLATTEN(input => ab.value:"vep")               v
WHERE  ab.value:"alt"::string          = 'T'
  AND (v.value:"Gene"::string          = 'BRCA1' 
       OR v.value:"SYMBOL"::string     = 'BRCA1')
  AND  v.value:"Consequence"::string ILIKE '%missense_variant%'
ORDER BY u."start_position";