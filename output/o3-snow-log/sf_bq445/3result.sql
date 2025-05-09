WITH vep_variants AS (        -- only BRCA1 annotations near its known locus
    SELECT
        v.value:"SYMBOL"::STRING           AS "SYMBOL",
        v.value:"Consequence"::STRING      AS "Consequence",
        v.value:"Protein_position"::STRING AS "Protein_position",
        t."start_position",
        t."end_position"
    FROM "GNOMAD"."GNOMAD"."V2_1_1_GENOMES__CHR17"  t
         , LATERAL FLATTEN(input => t."alternate_bases")                ab
         , LATERAL FLATTEN(input => ab.value:"vep")                     v
    WHERE t."start_position" BETWEEN 41190000 AND 41330000              -- BRCA1 region (GRCh37)
      AND v.value:"SYMBOL"::STRING = 'BRCA1'
),

region AS (                    -- genomic span of BRCA1 variants
    SELECT
        MIN("start_position") AS "min_start",
        MAX("end_position")   AS "max_end"
    FROM vep_variants
),

missense AS (                  -- BRCA1 missense variants within that span
    SELECT
        "Protein_position"
    FROM vep_variants, region
    WHERE "Consequence" ILIKE '%missense_variant%'
      AND "Protein_position" IS NOT NULL
      AND "start_position" BETWEEN region."min_start" AND region."max_end"
)

SELECT "Protein_position"
FROM missense
ORDER BY TO_NUMBER(SPLIT_PART("Protein_position", '/', 1)) ASC
LIMIT 1;