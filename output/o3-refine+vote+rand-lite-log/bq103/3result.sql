WITH region_variants AS (
  SELECT
    start_position,
    -- sum AC over all alternate alleles for each variant
    (SELECT SUM(alt.AC)
       FROM UNNEST(alternate_bases) AS alt) AS variant_AC,
    AN
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE reference_name = 'chr1'
    AND start_position BETWEEN 55039447 AND 55064852
),
gene_list AS (
  SELECT DISTINCT ve.SYMBOL
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` t
  CROSS JOIN UNNEST(t.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)          AS ve
  WHERE t.reference_name = 'chr1'
    AND t.start_position BETWEEN 55039447 AND 55064852
    AND ve.SYMBOL IS NOT NULL
)
SELECT
  COUNT(*)                                                      AS num_variants,
  SUM(variant_AC)                                               AS total_allele_count,
  SUM(AN)                                                       AS total_AN,
  (SELECT ARRAY_AGG(SYMBOL ORDER BY SYMBOL) FROM gene_list)     AS distinct_gene_symbols,
  CAST(55064852 - 55039447 + 1 AS FLOAT64) / COUNT(*)           AS mutation_density
FROM region_variants;