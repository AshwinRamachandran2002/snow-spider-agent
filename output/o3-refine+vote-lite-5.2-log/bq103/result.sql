-- Summary statistics for chr1:55039447‑55064852 using gnomAD v3 genomes
WITH region_variants AS (
  SELECT
    start_position,
    alternate_bases,     -- array of structs that contains AC and nested VEP
    AN                   -- number of alleles observed at the site
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE start_position BETWEEN 55039447 AND 55064852
),

-- 1) basic counts
variant_counts AS (
  SELECT
    COUNT(*)     AS num_variants,
    SUM(AN)      AS total_AN
  FROM region_variants
),

-- 2) sum of allele counts across all alternates
allele_counts AS (
  SELECT
    SUM(ab.AC) AS total_AC
  FROM region_variants
  CROSS JOIN UNNEST(alternate_bases) AS ab
),

-- 3) collect distinct gene symbols from VEP annotations
gene_symbols AS (
  SELECT
    ARRAY_AGG(DISTINCT v.SYMBOL ORDER BY v.SYMBOL) AS gene_symbols
  FROM region_variants rv
  CROSS JOIN UNNEST(rv.alternate_bases) AS ab
  LEFT JOIN UNNEST(ab.vep) AS v            -- vep is inside each alternate_base struct
  WHERE v.SYMBOL IS NOT NULL
)

SELECT
  vc.num_variants                       AS number_of_variants,
  ac.total_AC                           AS total_allele_count,
  vc.total_AN                           AS total_number_of_alleles,
  gs.gene_symbols                       AS distinct_gene_symbols,
  25406.0 / vc.num_variants             AS mutation_density_bp_per_variant
FROM variant_counts vc
CROSS JOIN allele_counts ac
CROSS JOIN gene_symbols gs;