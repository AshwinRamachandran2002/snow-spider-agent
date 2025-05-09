WITH variant_counts AS (
  SELECT
    reference_name,
    start,
    `end`,
    reference_bases,
    alt_base AS alternate_bases,
    VT AS variant_type,
    ROUND(AF, 4) AS allele_frequencies,
    -- Observed counts
    SUM(CASE WHEN c.genotype[SAFE_OFFSET(0)] = 0 AND c.genotype[SAFE_OFFSET(1)] = 0 THEN 1 ELSE 0 END) AS observed_counts_homozygous_reference_genotypes,
    SUM(CASE WHEN (c.genotype[SAFE_OFFSET(0)] = 0 AND c.genotype[SAFE_OFFSET(1)] = 1) OR
                   (c.genotype[SAFE_OFFSET(0)] = 1 AND c.genotype[SAFE_OFFSET(1)] = 0) THEN 1 ELSE 0 END) AS observed_counts_heterozygous_genotypes,
    SUM(CASE WHEN c.genotype[SAFE_OFFSET(0)] = 1 AND c.genotype[SAFE_OFFSET(1)] = 1 THEN 1 ELSE 0 END) AS observed_counts_homozygous_alternate_genotypes,
    COUNT(*) AS total_individuals
  FROM `genomics-public-data.1000_genomes.variants`,
    UNNEST(alternate_bases) AS alt_base,
    UNNEST(`call`) AS c
  WHERE
    reference_name = '17'
    AND start >= 41196311
    AND `end` <= 41277499
    AND ARRAY_LENGTH(alternate_bases) = 1
    AND AF IS NOT NULL
    AND c.genotype[SAFE_OFFSET(0)] >= 0
    AND c.genotype[SAFE_OFFSET(1)] >= 0
  GROUP BY
    reference_name, start, `end`, reference_bases, alt_base, VT, AF
)
SELECT
  reference_name,
  start,
  `end`,
  reference_bases,
  alternate_bases,
  variant_type,
  ROUND(
    (
      POWER(observed_counts_homozygous_reference_genotypes - expected_counts_homozygous_reference_genotypes, 2) / NULLIF(expected_counts_homozygous_reference_genotypes, 0) +
      POWER(observed_counts_heterozygous_genotypes - expected_counts_heterozygous_genotypes, 2) / NULLIF(expected_counts_heterozygous_genotypes, 0) +
      POWER(observed_counts_homozygous_alternate_genotypes - expected_counts_homozygous_alternate_genotypes, 2) / NULLIF(expected_counts_homozygous_alternate_genotypes, 0)
    ), 4
  ) AS chi_squared_score,
  observed_counts_homozygous_reference_genotypes,
  ROUND(expected_counts_homozygous_reference_genotypes, 4) AS expected_counts_homozygous_reference_genotypes,
  observed_counts_heterozygous_genotypes,
  ROUND(expected_counts_heterozygous_genotypes, 4) AS expected_counts_heterozygous_genotypes,
  observed_counts_homozygous_alternate_genotypes,
  ROUND(expected_counts_homozygous_alternate_genotypes, 4) AS expected_counts_homozygous_alternate_genotypes,
  allele_frequencies
FROM (
  SELECT
    vc.*,
    -- Expected counts under Hardy-Weinberg equilibrium
    total_individuals * POWER(1 - allele_frequencies, 2) AS expected_counts_homozygous_reference_genotypes,
    total_individuals * 2 * allele_frequencies * (1 - allele_frequencies) AS expected_counts_heterozygous_genotypes,
    total_individuals * POWER(allele_frequencies, 2) AS expected_counts_homozygous_alternate_genotypes
  FROM variant_counts AS vc
)
ORDER BY start