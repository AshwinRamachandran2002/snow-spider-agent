WITH region AS (
  SELECT 55039447 AS region_start, 55064852 AS region_end
),
variants AS (
  -- one row per VCF record (= variant)
  SELECT
    g.reference_name,
    g.start_position,
    g.end_position,
    g.reference_bases,
    g.AN,
    SUM(ab.AC) AS variant_AC
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` AS g
  CROSS JOIN UNNEST(g.alternate_bases) AS ab
  WHERE g.reference_name = 'chr1'
    AND g.start_position BETWEEN 55039447 AND 55064852
  GROUP BY
    g.reference_name,
    g.start_position,
    g.end_position,
    g.reference_bases,
    g.AN
),
variant_stats AS (
  SELECT
    COUNT(*)        AS variants,
    SUM(variant_AC) AS total_allele_count,
    SUM(AN)         AS total_number_of_alleles
  FROM variants
),
gene_symbols AS (
  SELECT
    STRING_AGG(DISTINCT v.SYMBOL, ',' ORDER BY v.SYMBOL) AS gene_symbols
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` AS g
  CROSS JOIN UNNEST(g.alternate_bases) AS ab
  CROSS JOIN UNNEST(ab.vep) AS v
  WHERE g.reference_name = 'chr1'
    AND g.start_position BETWEEN 55039447 AND 55064852
    AND v.SYMBOL IS NOT NULL
)
SELECT
  vs.variants,
  vs.total_allele_count,
  vs.total_number_of_alleles,
  gs.gene_symbols,
  ROUND((55064852 - 55039447 + 1) / vs.variants, 4) AS mutation_density_bp_per_variant
FROM variant_stats AS vs
CROSS JOIN gene_symbols AS gs;