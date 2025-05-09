WITH gene_bounds AS (
    /* find the BRCA1-annotated variants and get the outermost co-ordinates */
    SELECT  MIN(t."start_position") AS min_start ,
            MAX(t."end_position")   AS max_end
    FROM    "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"  t,
            LATERAL FLATTEN( INPUT => t."alternate_bases")                ab,
            LATERAL FLATTEN( INPUT => ab.value:"vep")                     v
    WHERE   v.value:"SYMBOL"::string = 'BRCA1'
),
missense_variants AS (
    /* within that BRCA1 region, keep only missense VEP entries
       and capture their Protein_position field                */
    SELECT  DISTINCT
            v.value:"Protein_position"::string          AS protein_position ,
            TO_NUMBER( REGEXP_SUBSTR(
                         v.value:"Protein_position"::string , '^[0-9]+')
                      )                                 AS protein_start
    FROM    "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"  t
    JOIN    gene_bounds   g
           ON t."start_position" >= g.min_start
          AND t."end_position"   <= g.max_end,
            LATERAL FLATTEN( INPUT => t."alternate_bases")                ab,
            LATERAL FLATTEN( INPUT => ab.value:"vep")                     v
    WHERE   v.value:"Consequence"::string ILIKE '%missense_variant%'
      AND   v.value:"Protein_position"        IS NOT NULL
)
SELECT  protein_position
FROM    missense_variants
ORDER BY protein_start ASC NULLS LAST
LIMIT 1;