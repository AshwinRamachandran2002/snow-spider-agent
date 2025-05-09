/*  Find BRCA1 region on chr17 (v2.1.1 genomes) and, inside that span,
    return the smallest protein position among all missense variants      */

WITH brca_bounds AS (     -- region limits, restrict scan to 40-45 Mb window
    SELECT  MIN(t."start_position") AS min_start ,
            MAX(t."end_position")   AS max_end
    FROM    GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17"  t
            , LATERAL FLATTEN(INPUT => t."alternate_bases")              ab
            , LATERAL FLATTEN(INPUT => ab.value:"vep")                   v
    WHERE   t."start_position" BETWEEN 40000000 AND 45000000  -- rough BRCA1 window
      AND   v.value:"SYMBOL"::string = 'BRCA1'
),

missense_variants AS (    -- missense variants that lie inside the BRCA1 span
    SELECT DISTINCT
           v.value:"Protein_position"::string                         AS protein_pos ,
           TO_NUMBER(SPLIT_PART(v.value:"Protein_position"::string,'/',1)) AS aa_start
    FROM   GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17"  t
           JOIN brca_bounds b
             ON  t."start_position" BETWEEN b.min_start AND b.max_end
           , LATERAL FLATTEN(INPUT => t."alternate_bases")            ab
           , LATERAL FLATTEN(INPUT => ab.value:"vep")                 v
    WHERE  v.value:"Protein_position" IS NOT NULL
      AND  v.value:"Consequence"::string ILIKE '%missense_variant%'
)

SELECT  protein_pos AS "Protein_position"
FROM    missense_variants
ORDER BY aa_start ASC NULLS LAST
LIMIT 1;