/* 1.  Locate the BRCA1 region on chr17 (min start & max end)
   2.  Restrict the main table to that region **before** flattening
   3.  From variants in the region return the first missense-variant
       Protein_position (sorted numerically)                                   */
WITH gene_bounds AS (
    SELECT  MIN(t."start_position") AS min_start ,
            MAX(t."end_position")   AS max_end
    FROM    "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"  t
            ,LATERAL FLATTEN(INPUT => t."alternate_bases") alt
            ,LATERAL FLATTEN(INPUT => alt.value:"vep")     v
    WHERE   v.value:"SYMBOL"::STRING = 'BRCA1'
),
brca1_region AS (                     -- variants inside the BRCA1 genomic span
    SELECT  t.*
    FROM    "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"  t
            JOIN gene_bounds g
              ON t."start_position" >= g.min_start
             AND t."end_position"   <= g.max_end
)
SELECT DISTINCT
       vep.value:"Protein_position"::STRING  AS protein_position
FROM   brca1_region  b
       ,LATERAL FLATTEN(INPUT => b."alternate_bases") alt
       ,LATERAL FLATTEN(INPUT => alt.value:"vep")      vep
WHERE  vep.value:"Consequence"::STRING ILIKE '%missense_variant%'
  AND  vep.value:"Protein_position" IS NOT NULL
ORDER BY
       TRY_TO_NUMBER(SPLIT_PART(vep.value:"Protein_position"::STRING,'/',1)) ASC,
       vep.value:"Protein_position"::STRING ASC
LIMIT 1;