-- Summary statistics for gnomAD v3 genomes in chr1: 55 039 447–55 064 852
WITH region AS (
  SELECT
    start_position,
    alt.alt                        AS alt_allele,
    alt.AC                         AS AC,
    g.AN                           AS AN,
    vep.SYMBOL                     AS gene
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` AS g
  CROSS JOIN UNNEST(g.alternate_bases)          AS alt
  LEFT  JOIN UNNEST(alt.vep)                    AS vep
  WHERE g.reference_name = 'chr1'
    AND g.start_position BETWEEN 55039447 AND 55064852
)
SELECT
  COUNT(DISTINCT CONCAT(CAST(start_position AS STRING),':',alt_allele))
      AS num_variants,
  SUM(AC)                                     AS total_allele_count,
  SUM(AN)                                     AS total_number_of_alleles,
  ARRAY_AGG(DISTINCT gene IGNORE NULLS)       AS distinct_gene_symbols,
  (55064852 - 55039447 + 1) * 1.0 /
      COUNT(DISTINCT CONCAT(CAST(start_position AS STRING),':',alt_allele))
      AS bp_per_variant
FROM region;