/* summary statistics for chr1:55,039,447-55,064,852 in gnomAD v3 genomes */
WITH region_len AS (
    SELECT 55064852 - 55039447 + 1 AS len            -- interval length (inclusive)
),
filtered AS (                                        -- variants within the region
    SELECT 
        "start_position",
        "AN",
        "alternate_bases"
    FROM GNOMAD.GNOMAD."V3_GENOMES__CHR1"
    WHERE "reference_name" = 'chr1'
      AND "start_position" BETWEEN 55039447 AND 55064852
),
allele_counts AS (                                   -- sum of allele counts in all alt alleles
    SELECT SUM(ab.value:"AC"::NUMBER) AS total_ac
    FROM filtered f,
         LATERAL FLATTEN(INPUT => f."alternate_bases") ab
),
gene_symbols AS (                                    -- distinct gene symbols from VEP
    SELECT DISTINCT v.value:"SYMBOL"::STRING AS symbol
    FROM filtered f,
         LATERAL FLATTEN(INPUT => f."alternate_bases") ab,
         LATERAL FLATTEN(INPUT => ab.value:"vep") v
),
symbol_list AS (                                     -- concatenated list of symbols
    SELECT LISTAGG(symbol, ',') WITHIN GROUP (ORDER BY symbol) AS genes
    FROM gene_symbols
),
agg AS (                                             -- variant count and total AN
    SELECT COUNT(*) AS variant_cnt,
           SUM("AN") AS total_an
    FROM filtered
)
SELECT
    agg.variant_cnt                           AS number_of_variants,
    ac.total_ac                               AS total_allele_count,
    agg.total_an                              AS total_an,
    sl.genes                                  AS distinct_gene_symbols,
    (rl.len::FLOAT) / agg.variant_cnt         AS mutation_density          -- bases per variant
FROM agg
CROSS JOIN allele_counts ac
CROSS JOIN symbol_list  sl
CROSS JOIN region_len   rl;