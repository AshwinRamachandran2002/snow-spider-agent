WITH variants AS (
  SELECT
    start_position,
    AN,
    alternate_bases
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE reference_name = 'chr1'
    AND start_position BETWEEN 55039447 AND 55064852
),
variant_stats AS (
  SELECT
    COUNT(*) AS variants,
    SUM(AN)  AS total_number_of_alleles
  FROM variants
),
allele_stats AS (
  SELECT
    SUM(IFNULL(alt.AC, 0)) AS total_allele_count
  FROM variants
  CROSS JOIN UNNEST(alternate_bases) AS alt
),
gene_stats AS (
  SELECT
    ARRAY_TO_STRING(
      ARRAY(
        SELECT DISTINCT vep.SYMBOL
        FROM variants
        CROSS JOIN UNNEST(alternate_bases) AS alt
        LEFT JOIN UNNEST(alt.vep) AS vep
        WHERE vep.SYMBOL IS NOT NULL
        ORDER BY vep.SYMBOL
      ),
    ', ') AS gene_symbols
)
SELECT
  vs.variants,
  als.total_allele_count,
  vs.total_number_of_alleles,
  gs.gene_symbols,
  ROUND((55064852 - 55039447) / vs.variants, 4) AS mutation_density_bp_per_variant
FROM variant_stats AS vs
CROSS JOIN allele_stats AS als
CROSS JOIN gene_stats  AS gs;