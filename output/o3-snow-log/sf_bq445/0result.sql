/* one-pass scan of chr17: keep only VEP records that are either from BRCA1
   (needed to discover the gene limits) or are missense variants (needed for
   the final answer)                                               */
WITH vep_flat AS (
    SELECT
        t."start_position"                                        AS start_pos ,
        t."end_position"                                          AS end_pos  ,
        vep.value:"SYMBOL"::STRING                                AS symbol   ,
        vep.value:"Consequence"::STRING                           AS conseq   ,
        vep.value:"Protein_position"::STRING                      AS protein_pos ,
        /* compute BRCA1 boundaries once, available to every row */
        MIN( CASE WHEN vep.value:"SYMBOL"::STRING = 'BRCA1'
                  THEN t."start_position" END )                  OVER () AS min_start ,
        MAX( CASE WHEN vep.value:"SYMBOL"::STRING = 'BRCA1'
                  THEN t."end_position"   END )                  OVER () AS max_end
    FROM GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17"       t
         ,LATERAL FLATTEN( input => t."alternate_bases")          ab
         ,LATERAL FLATTEN( input => ab.value:"vep")               vep
    /* keep only rows relevant for either step to reduce work     */
    WHERE vep.value:"SYMBOL"::STRING    = 'BRCA1'
       OR vep.value:"Consequence"::STRING ILIKE '%missense_variant%'
)
SELECT protein_pos
FROM  (
        SELECT DISTINCT protein_pos
        FROM vep_flat
        WHERE start_pos >= min_start         -- inside BRCA1 span
          AND end_pos   <= max_end
          AND conseq    ILIKE '%missense_variant%'
          AND protein_pos IS NOT NULL
      )
ORDER BY REGEXP_SUBSTR(protein_pos, '^[0-9]+')::NUMBER ASC,
         protein_pos ASC
LIMIT 1;