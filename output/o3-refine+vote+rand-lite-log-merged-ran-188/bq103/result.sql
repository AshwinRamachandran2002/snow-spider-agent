/* Summary statistics for chr1:55,039,447-55,064,852 (gnomAD v3 genomes) */
WITH region_variants AS (
  SELECT *
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE reference_name = 'chr1'
    AND start_position BETWEEN 55039447 AND 55064852
),

-- 1) basic counts
variant_count AS (
  SELECT COUNT(*) AS num_variants
  FROM region_variants
),

-- 2) allele-level sums
allele_counts AS (
  SELECT
    SUM(alt.AC)            AS total_AC,
    SUM(alt.n_alt_alleles) AS total_n_alt_alleles
  FROM region_variants rv
  CROSS JOIN UNNEST(rv.alternate_bases) AS alt
),

-- 3) distinct genes hit
gene_list AS (
  SELECT ARRAY_AGG(DISTINCT vep.SYMBOL ORDER BY vep.SYMBOL) AS distinct_gene_symbols
  FROM region_variants rv
  CROSS JOIN UNNEST(rv.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)            AS vep
  WHERE vep.SYMBOL IS NOT NULL
)

SELECT
  55064852 - 55039447 + 1                                        AS region_length_bp,
  vc.num_variants,
  ac.total_AC,
  ac.total_n_alt_alleles,
  SAFE_DIVIDE(55064852 - 55039447 + 1, vc.num_variants)          AS bp_per_variant,
  gene_list.distinct_gene_symbols
FROM variant_count vc
CROSS JOIN allele_counts ac
CROSS JOIN gene_list;