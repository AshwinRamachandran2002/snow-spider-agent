-- Summary statistics for variants in chr1:55,039,447–55,064,852 (gnomAD v3 genomes)
WITH region AS (
  SELECT
    55039447 AS region_start,
    55064852 AS region_end,
    55064852 - 55039447 + 1 AS region_length_bp
)
SELECT
  COUNT(*)                                                            AS variant_count,
  SUM(alt.AC)                                                         AS total_allele_count,
  SUM(alt.n_alt_alleles)                                              AS total_alt_alleles,
  ARRAY_AGG(DISTINCT vep.SYMBOL IGNORE NULLS)                         AS gene_symbols,
  r.region_length_bp                                                  AS region_length_bp,
  ROUND(r.region_length_bp / COUNT(*), 2)                             AS bases_per_variant
FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` AS g
CROSS JOIN region AS r
JOIN UNNEST(g.alternate_bases) AS alt
LEFT JOIN UNNEST(alt.vep) AS vep
ON TRUE
WHERE g.reference_name = 'chr1'
  AND g.start_position BETWEEN r.region_start AND r.region_end
GROUP BY r.region_length_bp;