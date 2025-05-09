/* First (smallest) BRCA1 missense-variant protein position on chr17 (gnomAD v2.1.1 genomes)
   BRCA1 (GRCh37) genomic span: chr17:43,044,295-43,125,483                           */
WITH bounds AS (                    -- constant genomic coordinates of BRCA1
    SELECT 43044295 AS min_start , 43125483 AS max_end
),
missense AS (
    SELECT DISTINCT
           vep.value:"Protein_position"::string AS protein_position
    FROM   "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"  t
           JOIN bounds b
             ON t."start_position" BETWEEN b.min_start AND b.max_end
         , LATERAL FLATTEN(input => t."alternate_bases")  alt
         , LATERAL FLATTEN(input => alt.value:"vep")      vep
    WHERE  vep.value:"Consequence"::string ILIKE '%missense_variant%'
      AND  vep.value:"Protein_position" IS NOT NULL
)
SELECT protein_position
FROM   missense
ORDER  BY TRY_TO_NUMBER(SPLIT_PART(protein_position,'/',1))
FETCH  FIRST 1 ROWS ONLY;