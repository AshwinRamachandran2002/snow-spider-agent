/*  Start-positions of C→T missense variants in BRCA1
    gnomAD v2.1.1 (GRCh37 / hg19 coordinates)                           */

WITH exomes AS (     -- chr17 exomes, restrict to BRCA1 window & ref-base
    SELECT  "start_position",
            "reference_bases",
            "alternate_bases"
    FROM    GNOMAD.GNOMAD."V2_1_1_EXOMES__CHR17"
    WHERE   "start_position" BETWEEN 41190000 AND 41300000   -- BRCA1 (hg19)
      AND   "reference_bases" = 'C'
),
genomes AS (         -- chr17 genomes, same pre-filters
    SELECT  "start_position",
            "reference_bases",
            "alternate_bases"
    FROM    GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17"
    WHERE   "start_position" BETWEEN 41190000 AND 41300000
      AND   "reference_bases" = 'C'
),
combined AS (        -- union exomes + genomes (same column list)
    SELECT * FROM exomes
    UNION ALL
    SELECT * FROM genomes
)
SELECT  DISTINCT c."start_position"
FROM     combined                                          AS c
         , LATERAL FLATTEN( INPUT => c."alternate_bases" )         ab
         , LATERAL FLATTEN( INPUT => ab.value:"vep" )              v
WHERE    ab.value:"alt"::string             = 'T'                  -- C→T
  AND    v.value:"SYMBOL"::string           = 'BRCA1'              -- gene
  AND    v.value:"Consequence"::string ILIKE '%missense_variant%'; -- missense