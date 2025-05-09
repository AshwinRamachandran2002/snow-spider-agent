/* -----------------------------------------------------------
   Summary statistics for gnomAD v3 variants on chr1
   coordinates 55,039,447 – 55,064,852 (1-based, inclusive)
------------------------------------------------------------*/
WITH region_variants AS (           -- all variant rows that overlap the interval
    SELECT
        "start_position",
        "end_position",
        "AN",
        "alternate_bases"
    FROM   GNOMAD.GNOMAD."V3_GENOMES__CHR1"
    WHERE  "start_position" BETWEEN 55039447 AND 55064852
),
variant_stats AS (                  -- counts taken once per variant row
    SELECT
        COUNT(*)              AS num_variants,
        SUM("AN")             AS total_number_of_alleles
    FROM region_variants
),
alt_level AS (                      -- one row per alternate allele
    SELECT
        alt.value:"AC"::NUMBER                 AS ac,
        vep.value:"SYMBOL"::STRING            AS gene_symbol
    FROM   region_variants rv
           ,LATERAL FLATTEN(input => rv."alternate_bases")                alt
           ,LATERAL FLATTEN(input => alt.value:"vep")                      vep
),
allele_stats AS (                   -- aggregate over all alternate alleles
    SELECT
        SUM(ac)                      AS total_allele_count
    FROM alt_level
),
gene_list AS (                      -- collect distinct gene symbols
    SELECT
        ARRAY_AGG(DISTINCT gene_symbol) AS distinct_gene_symbols
    FROM   alt_level
    WHERE  gene_symbol IS NOT NULL
)
SELECT
    vs.num_variants                                                  AS number_of_variants,
    als.total_allele_count                                           AS total_allele_count,
    vs.total_number_of_alleles                                       AS total_number_of_alleles,
    gl.distinct_gene_symbols                                         AS gene_symbols,
    25406.0 / vs.num_variants                                        AS mutation_density   -- region length / #variants
FROM variant_stats  vs
CROSS JOIN allele_stats als
CROSS JOIN gene_list    gl;