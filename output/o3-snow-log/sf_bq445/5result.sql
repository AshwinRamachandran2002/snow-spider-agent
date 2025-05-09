WITH missense AS (
    SELECT DISTINCT
           vep.value:"Protein_position"::string AS protein_pos
    FROM GNOMAD.GNOMAD."V2_1_1_GENOMES__CHR17" g
    ,    LATERAL FLATTEN(input => g."alternate_bases") ab
    ,    LATERAL FLATTEN(input => ab.value:"vep")      vep
    WHERE vep.value:"SYMBOL"::string = 'BRCA1'
      AND POSITION('missense_variant' IN vep.value:"Consequence"::string) > 0
      AND vep.value:"Protein_position" IS NOT NULL
)
SELECT protein_pos
FROM   missense
ORDER  BY TO_NUMBER(SPLIT_PART(protein_pos,'/',1)) ASC
LIMIT 1;