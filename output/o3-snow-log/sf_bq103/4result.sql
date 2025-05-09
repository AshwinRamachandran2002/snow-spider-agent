WITH sites AS (        -- one row per record lying in the interval
    SELECT DISTINCT
        "start_position",
        "end_position",
        "AN"
    FROM GNOMAD.GNOMAD."V3_GENOMES__CHR1"
    WHERE "reference_name" = 'chr1'
      AND "start_position" BETWEEN 55039447 AND 55064852
),
variants AS (          -- explode JSON -> one row per alternate allele
    SELECT
        s."start_position",
        s."end_position",
        s."AN",
        alt.value:"alt"::STRING        AS allele,
        alt.value:"AC" ::NUMBER        AS ac,
        ve.value:"SYMBOL"::STRING      AS gene_symbol
    FROM GNOMAD.GNOMAD."V3_GENOMES__CHR1"      AS s
         , LATERAL FLATTEN(INPUT => s."alternate_bases") AS alt
         , LATERAL FLATTEN(INPUT => alt.value:"vep")      AS ve
    WHERE s."reference_name" = 'chr1'
      AND s."start_position" BETWEEN 55039447 AND 55064852
),
summary AS (
    SELECT
        COUNT(DISTINCT CONCAT("start_position",'|',allele))    AS num_variants,
        SUM(ac)                                                AS total_ac,
        LISTAGG(DISTINCT gene_symbol, ', ')                    AS gene_symbols
    FROM variants
),
tot_an AS (
    SELECT SUM("AN") AS total_an
    FROM   sites
)

SELECT
    s.num_variants                          AS "NUM_VARIANTS",
    s.total_ac                              AS "TOTAL_ALLELE_COUNT",
    t.total_an                              AS "TOTAL_ALLELES",
    s.gene_symbols                          AS "GENE_SYMBOLS",
    ROUND(25406.0 / s.num_variants , 4)     AS "MUTATION_DENSITY"   -- bp per variant
FROM summary  s
CROSS JOIN tot_an t;