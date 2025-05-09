-- Summary statistics for chr1:55039447-55064852 in gnomAD v3 genomes
WITH region_variants AS (
  SELECT
    CONCAT(start_position,'_',end_position)        AS variant_id,
    alternate_bases
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE reference_name = 'chr1'
    AND start_position BETWEEN 55039447 AND 55064852
),
flat AS (
  SELECT
    variant_id,
    alt.AC                                         AS allele_count,          -- per-alt allele count
    alt.n_alt_alleles                              AS n_alt_alleles,         -- # alt alleles at this locus
    vep.SYMBOL                                     AS gene_symbol
  FROM region_variants,
       UNNEST(alternate_bases)  AS alt
  LEFT JOIN UNNEST(alt.vep)      AS vep
  ON TRUE
),
per_variant AS (
  -- Collapse to one row per genomic position
  SELECT
    variant_id,
    SUM(allele_count)            AS total_AC_variant,
    MAX(n_alt_alleles)           AS n_alt_alleles_variant
  FROM flat
  GROUP BY variant_id
),
overall AS (
  SELECT
    COUNT(*)                     AS n_variants,
    SUM(total_AC_variant)        AS total_allele_count,
    SUM(n_alt_alleles_variant)   AS total_number_of_alleles
  FROM per_variant
)
SELECT
  o.n_variants,
  o.total_allele_count,
  o.total_number_of_alleles,
  ARRAY(SELECT DISTINCT gene_symbol
        FROM flat
        WHERE gene_symbol IS NOT NULL)             AS distinct_gene_symbols,
  25406                                            AS region_length_bp,      -- inclusive (55064852-55039447+1)
  CAST(25406 AS FLOAT64) / o.n_variants           AS mutation_density_bp_per_variant
FROM overall o;