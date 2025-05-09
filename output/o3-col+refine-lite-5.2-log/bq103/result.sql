-- Summary statistics for chr1: 55 039 447‑55 064 852 (gnomAD v3 genomes)
WITH region AS (
  SELECT *
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE start_position BETWEEN 55039447 AND 55064852
),
variant_stats AS (
  SELECT
    COUNT(*)          AS num_variants,
    SUM(AN)           AS total_AN
  FROM region
),
allele_stats AS (
  SELECT
    SUM(ab.AC)        AS total_AC
  FROM region, UNNEST(alternate_bases) AS ab
),
gene_stats AS (
  SELECT
    ARRAY_AGG(DISTINCT v.SYMBOL IGNORE NULLS) AS distinct_gene_symbols
  FROM region,
       UNNEST(alternate_bases) AS ab,
       UNNEST(ab.vep)          AS v
)
SELECT
  variant_stats.num_variants,
  allele_stats.total_AC,
  variant_stats.total_AN,
  gene_stats.distinct_gene_symbols,
  25406.0 / variant_stats.num_variants AS bp_per_variant
FROM variant_stats, allele_stats, gene_stats;