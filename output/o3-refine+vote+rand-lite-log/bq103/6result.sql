-- Summary statistics for chr1:55039447‑55064852 using gnomAD v3 genomes
WITH region_variants AS (
  SELECT *
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE start_position BETWEEN 55039447 AND 55064852
),
stats AS (
  SELECT
    COUNT(*) AS num_variants,
    -- sum of AC across every alternate allele for each variant
    SUM( (SELECT SUM(ab.AC) FROM UNNEST(alternate_bases) ab) ) AS total_allele_count,
    SUM(AN) AS total_number_of_alleles
  FROM region_variants
),
gene_list AS (
  SELECT
    ARRAY_AGG(DISTINCT v.SYMBOL ORDER BY v.SYMBOL) AS distinct_gene_symbols
  FROM region_variants r
  CROSS JOIN UNNEST(r.alternate_bases)  AS ab
  CROSS JOIN UNNEST(ab.vep)             AS v
  WHERE v.SYMBOL IS NOT NULL
    AND v.SYMBOL != ''
)
SELECT
  s.num_variants,
  s.total_allele_count,
  s.total_number_of_alleles,
  g.distinct_gene_symbols,
  SAFE_DIVIDE(55064852 - 55039447 + 1, s.num_variants) AS bp_per_variant
FROM stats AS s
CROSS JOIN gene_list AS g;