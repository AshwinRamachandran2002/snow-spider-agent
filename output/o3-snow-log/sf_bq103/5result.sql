/*---------------------------------------------------------------
  gnomAD v3 – chromosome 1, positions 55 039 447 – 55 064 852
  Summary: #variants, total AC, total AN, gene symbols, density
----------------------------------------------------------------*/
WITH base AS (                     -- limit rows to region first
    SELECT
        "start_position",
        "end_position",
        "AN"                 AS variant_an,
        "alternate_bases"
    FROM GNOMAD.GNOMAD."V3_GENOMES__CHR1"
    WHERE "start_position" BETWEEN 55039447 AND 55064852
),

alts AS (                          -- one row per ALT allele
    SELECT
        b."start_position",
        b."end_position",
        b.variant_an,
        f.value:"AC"::NUMBER        AS ac,
        f.value:"vep"               AS vep_json
    FROM base b,
         LATERAL FLATTEN (INPUT => b."alternate_bases") f
),

alts_gene AS (                     -- attach gene symbols when present
    SELECT
        a.*,
        vg.value:"SYMBOL"::STRING   AS gene_symbol
    FROM alts a
         LEFT JOIN LATERAL FLATTEN (INPUT => a.vep_json) vg
),

prep AS (                          -- keep AN once per variant
    SELECT
        *,
        CASE 
             WHEN ROW_NUMBER() OVER (
                       PARTITION BY "start_position","end_position"
                       ORDER BY "start_position") = 1
             THEN variant_an 
             ELSE 0 
        END AS an_once
    FROM alts_gene
)

SELECT
    COUNT(DISTINCT "start_position","end_position")                                    AS "NUMBER_OF_VARIANTS",
    SUM(ac)                                                                            AS "TOTAL_ALLELE_COUNT",
    SUM(an_once)                                                                       AS "TOTAL_NUMBER_OF_ALLELES",
    LISTAGG(DISTINCT gene_symbol, ', ') WITHIN GROUP (ORDER BY gene_symbol)            AS "GENE_SYMBOLS",
    ( (55064852 - 55039447 + 1)::FLOAT                                                 -- region length
      / NULLIF(COUNT(DISTINCT "start_position","end_position"), 0) )                   AS "MUTATION_DENSITY"
FROM prep;