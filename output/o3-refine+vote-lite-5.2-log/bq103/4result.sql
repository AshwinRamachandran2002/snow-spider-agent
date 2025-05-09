-- summary statistics for chr1:55039447-55064852 using gnomAD v3 genomes
WITH region_variants AS (
  SELECT
    start_position,
    AN,
    alternate_bases
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE start_position BETWEEN 55039447 AND 55064852
),

-- sum all alternate‑allele counts (AC) across every allele for each variant
allele_totals AS (
  SELECT SUM(alt.AC) AS total_allele_count
  FROM region_variants rv
  CROSS JOIN UNNEST(rv.alternate_bases) AS alt
),

-- collect distinct gene symbols from the VEP annotations
genes AS (
  SELECT DISTINCT vep.SYMBOL
  FROM region_variants rv
  CROSS JOIN UNNEST(rv.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep) AS vep
  WHERE vep.SYMBOL IS NOT NULL
)

SELECT
  (SELECT COUNT(*)              FROM region_variants)                AS number_of_variants,
  (SELECT total_allele_count    FROM allele_totals)                  AS total_allele_count,
  (SELECT SUM(AN)               FROM region_variants)                AS total_number_of_alleles,
  (SELECT STRING_AGG(SYMBOL, ', ' ORDER BY SYMBOL) FROM genes)       AS distinct_gene_symbols,
  -- region length = 55,064,852‑55,039,447+1 = 25,406 bp
  25406.0 / (SELECT COUNT(*) FROM region_variants)                   AS mutation_density_bp_per_variant
;