-- Summary statistics for chr1:55 039 447–55 064 852 in gnomAD v3 genomes
WITH region_variants AS (
  SELECT *
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE reference_name = 'chr1'
    AND start_position BETWEEN 55039447 AND 55064852
),

region_alts AS (
  SELECT
    v.start_position,
    alt.*
  FROM region_variants AS v
  CROSS JOIN UNNEST(v.alternate_bases) AS alt
),

gene_symbols AS (
  SELECT DISTINCT
    vep.SYMBOL
  FROM region_alts
  CROSS JOIN UNNEST(region_alts.vep) AS vep
  WHERE vep.SYMBOL IS NOT NULL
    AND vep.SYMBOL <> ''
)

SELECT
  -- 1) total number of variant rows in the interval
  (SELECT COUNT(*) FROM region_variants)                          AS number_of_variants,

  -- 2) sum of alternate-allele counts (AC) across all ALT records
  (SELECT SUM(AC)  FROM region_alts)                              AS total_allele_count,

  -- 3) total number of ALT records (i.e., individual alternate alleles reported)
  (SELECT COUNT(*) FROM region_alts)                              AS total_alt_alleles,

  -- 4) comma-separated list of distinct gene symbols (VEP annotation)
  (SELECT STRING_AGG(SYMBOL, ',' ORDER BY SYMBOL)
   FROM gene_symbols)                                             AS distinct_gene_symbols,

  -- 5) mutation density = region length (inclusive) ÷ number of variants
  CAST((55064852 - 55039447 + 1) AS FLOAT64) /
  (SELECT COUNT(*) FROM region_variants)                          AS mutation_density
;