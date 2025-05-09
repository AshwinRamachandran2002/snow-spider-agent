WITH region AS (
  SELECT *
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE reference_name = 'chr1'
    AND start_position BETWEEN 55039447 AND 55064852
),
counts AS (
  SELECT
    COUNT(*)                        AS variants,
    SUM(AN)                         AS total_number_of_alleles,
    SUM(alt.AC)                     AS total_allele_count
  FROM region
  JOIN UNNEST(region.alternate_bases) AS alt
),
genes AS (
  SELECT ARRAY_TO_STRING(
           ARRAY_AGG(DISTINCT vep.SYMBOL ORDER BY vep.SYMBOL), ','
         ) AS gene_symbols
  FROM region
  JOIN UNNEST(region.alternate_bases) AS alt
  JOIN UNNEST(alt.vep)               AS vep
  WHERE vep.SYMBOL IS NOT NULL
)
SELECT
  counts.variants,
  counts.total_allele_count,
  counts.total_number_of_alleles,
  genes.gene_symbols,
  ROUND(25405.0 / counts.variants, 4) AS mutation_density_bp_per_variant
FROM counts
CROSS JOIN genes;