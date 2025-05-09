-- summary statistics for chr1:55039447-55064852 in gnomAD v3 genomes
WITH variant_level AS (
  SELECT
    t.reference_name,
    t.start_position,
    t.end_position,
    ANY_VALUE(t.AN)            AS AN,                             -- per‑variant total number of alleles
    SUM(alt.AC)                AS variant_AC,                     -- sum of allele counts of all alt alleles
    ARRAY_AGG(DISTINCT vep.SYMBOL IGNORE NULLS) AS symbols        -- distinct gene symbols for this variant
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` AS t
  JOIN UNNEST(t.alternate_bases) AS alt
  LEFT JOIN UNNEST(alt.vep) AS vep
  WHERE t.reference_name = 'chr1'
    AND t.start_position BETWEEN 55039447 AND 55064852
  GROUP BY t.reference_name, t.start_position, t.end_position
),
region_stats AS (
  SELECT
    COUNT(*)                           AS num_variants,
    SUM(variant_AC)                    AS total_allele_count,
    SUM(AN)                            AS total_alleles,
    ARRAY(SELECT DISTINCT s
          FROM variant_level, UNNEST(symbols) AS s
          WHERE s IS NOT NULL)          AS distinct_gene_symbols
  FROM variant_level
)
SELECT
  num_variants,
  total_allele_count,
  total_alleles,
  distinct_gene_symbols,
  (55064852 - 55039447 + 1) * 1.0 / num_variants AS mutation_density   -- region length / variant count
FROM region_stats;