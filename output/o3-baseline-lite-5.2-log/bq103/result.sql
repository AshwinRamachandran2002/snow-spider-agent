-- Summary statistics for chr1:55039447-55064852 using gnomAD v3 genomes
WITH region_variants AS (
  SELECT *
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE start_position BETWEEN 55039447 AND 55064852
),
variant_stats AS (
  SELECT
    COUNT(*)                    AS num_variants,
    SUM(AN)                     AS total_AN
  FROM region_variants
),
allele_stats AS (
  -- sum AC across all alternate alleles
  SELECT
    SUM(ab.AC)                  AS total_AC
  FROM region_variants,
  UNNEST(alternate_bases) AS ab
),
gene_list AS (
  -- collect distinct gene symbols from VEP annotation
  SELECT
    ARRAY_AGG(DISTINCT v.SYMBOL IGNORE NULLS) AS gene_symbols
  FROM region_variants,
  UNNEST(alternate_bases) AS ab,
  UNNEST(ab.vep)          AS v
  WHERE v.SYMBOL IS NOT NULL
)
SELECT
  vs.num_variants,
  als.total_AC,
  vs.total_AN,
  gl.gene_symbols,
  -- region length (inclusive) divided by number of variants
  (55064852 - 55039447 + 1) * 1.0 / vs.num_variants AS mutation_density
FROM variant_stats vs
JOIN allele_stats als ON TRUE
JOIN gene_list     gl ON TRUE;