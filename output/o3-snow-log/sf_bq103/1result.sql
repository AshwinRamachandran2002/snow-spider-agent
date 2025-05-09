/*--------------------------------------------------------------------
  Summary statistics for gnomAD v3 variants on chr1:55039447-55064852
--------------------------------------------------------------------*/
WITH region_variants AS (          -- keep only columns we really need
    SELECT
        "start_position",
        "AN",
        "alternate_bases"
    FROM GNOMAD.GNOMAD."V3_GENOMES__CHR1"
    WHERE "start_position" BETWEEN 55039447 AND 55064852
),

/* basic counts that do NOT require JSON processing */
variant_stats AS (
    SELECT
        COUNT(*)        AS num_variants,
        SUM("AN")       AS total_alleles
    FROM region_variants
),

/* parse the JSON once to obtain total AC and gene symbols            */
allele_and_genes AS (
    SELECT
        /* total allele count (AC) summed across every alt allele      */
        SUM(
            TRY_TO_NUMBER( (ab.value:"AC")::STRING )
        )                                                     AS total_allele_count,

        /* distinct gene symbols from VEP annotations                 */
        ARRAY_AGG( DISTINCT (vep.value:"SYMBOL")::STRING )    AS gene_symbols
    FROM region_variants rv,
         LATERAL FLATTEN( INPUT => rv."alternate_bases" ) ab,
         LATERAL FLATTEN( INPUT => ab.value:"vep" )      vep
    WHERE vep.value:"SYMBOL" IS NOT NULL
)

SELECT
       vs.num_variants                                    AS "NUM_VARIANTS",
       ag.total_allele_count                              AS "TOTAL_ALLELE_COUNT",
       vs.total_alleles                                   AS "TOTAL_ALLELES",
       25406.0 / NULLIF(vs.num_variants, 0)               AS "MUTATION_DENSITY",   -- bp per variant
       ag.gene_symbols                                    AS "GENE_SYMBOLS"
FROM   variant_stats      vs
       JOIN allele_and_genes ag ON TRUE;