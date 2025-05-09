-- Summary statistics for chr1:55,039,447-55,064,852 in gnomAD v3 genomes
WITH region AS (
  SELECT *
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE reference_name = 'chr1'
    AND start_position BETWEEN 55039447 AND 55064852
),
allele_totals AS (
  SELECT
    SUM(alt.AC)                     AS total_AC,              -- summed allele count
    SUM(alt.AC_raw)                 AS total_AC_raw,          -- summed raw allele count
    SUM(alt.n_alt_alleles)          AS total_alt_alleles      -- number of alternate alleles
  FROM region
  CROSS JOIN UNNEST(alternate_bases) AS alt
),
gene_syms AS (
  SELECT ARRAY_AGG(DISTINCT vep.SYMBOL IGNORE NULLS) AS distinct_genes
  FROM region
  CROSS JOIN UNNEST(alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)          AS vep
),
variant_ct AS (
  SELECT COUNT(*) AS variant_count
  FROM region
)
SELECT
  55064852 - 55039447 + 1                             AS region_length,
  variant_count,                                      -- number of variant rows
  total_AC                                            AS total_allele_count,
  total_AC_raw                                        AS total_number_of_alleles,
  distinct_genes                                      AS gene_symbols,
  (55064852 - 55039447 + 1) / variant_count           AS bases_per_variant
FROM variant_ct
CROSS JOIN allele_totals
CROSS JOIN gene_syms;