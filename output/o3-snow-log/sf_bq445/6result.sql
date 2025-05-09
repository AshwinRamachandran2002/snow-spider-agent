WITH brca1_bounds AS (      -- min start / max end of BRCA1-annotated variants on chr17
    SELECT
        MIN(t."start_position") AS min_start ,
        MAX(t."end_position")   AS max_end
    FROM
        "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"  t,
        LATERAL FLATTEN( input => t."alternate_bases" )           alt,
        LATERAL FLATTEN( input => alt.value:"vep" )               vep
    WHERE
        t."start_position" BETWEEN 40000000 AND 45000000          -- window around BRCA1
        AND vep.value:"SYMBOL"::STRING = 'BRCA1'
),
missense AS (                -- missense variants inside that BRCA1 region
    SELECT DISTINCT
        vep.value:"Protein_position"::STRING                             AS protein_position ,
        TO_NUMBER( SPLIT_PART( vep.value:"Protein_position"::STRING , '/' , 1) ) 
                                                                        AS protein_start
    FROM
        "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"  t,
        brca1_bounds b,
        LATERAL FLATTEN( input => t."alternate_bases" )           alt,
        LATERAL FLATTEN( input => alt.value:"vep" )               vep
    WHERE
        t."start_position" BETWEEN b.min_start AND b.max_end
        AND vep.value:"Consequence"::STRING ILIKE '%missense_variant%'
        AND vep.value:"Protein_position" IS NOT NULL
)
SELECT  protein_position
FROM    missense
ORDER BY protein_start ASC NULLS LAST
LIMIT 1;