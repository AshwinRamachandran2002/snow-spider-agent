-- Summary statistics for gnomAD v3 genomes variants in chr1:55039447-55064852
WITH region AS (
  SELECT *
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE reference_name = 'chr1'
    AND start_position BETWEEN 55039447 AND 55064852
),
/* variant-level statistics */
stats AS (
  SELECT
    COUNT(*)                                   AS n_variants,
    SUM(alt.AC_raw)                            AS total_allele_count,
    SUM(ARRAY_LENGTH(alternate_bases))         AS total_number_of_alleles
  FROM region,
       UNNEST(alternate_bases) AS alt
),
/* distinct gene symbols from VEP annotations */
genes AS (
  SELECT DISTINCT vep.SYMBOL AS gene_symbol
  FROM region,
       UNNEST(alternate_bases) AS alt,
       UNNEST(alt.vep)         AS vep
  WHERE vep.SYMBOL IS NOT NULL
)
SELECT
  s.n_variants,
  s.total_allele_count,
  s.total_number_of_alleles,
  ARRAY_LENGTH(gene_list)                      AS n_genes,
  gene_list                                    AS gene_symbols,          -- array of distinct genes
  (25405.0 / s.n_variants)                     AS mutation_density_bp_per_variant
FROM stats         AS s
JOIN (
  SELECT ARRAY_AGG(gene_symbol ORDER BY gene_symbol) AS gene_list
  FROM genes
)              AS g
ON TRUE;