WITH variant_counts AS (
  SELECT
    v.reference_name,
    v.start,
    v.`end`,
    v.reference_bases,
    v.alternate_bases[OFFSET(0)] AS alternate_bases,
    v.VT AS variant_type,
    COUNTIF(ARRAY_LENGTH(c.genotype) = 2 AND c.genotype[OFFSET(0)] = 0 AND c.genotype[OFFSET(1)] = 0) AS obs_hom_ref,
    COUNTIF(ARRAY_LENGTH(c.genotype) = 2 AND (
      (c.genotype[OFFSET(0)] = 0 AND c.genotype[OFFSET(1)] = 1) OR
      (c.genotype[OFFSET(0)] = 1 AND c.genotype[OFFSET(1)] = 0)
    )) AS obs_het,
    COUNTIF(ARRAY_LENGTH(c.genotype) = 2 AND c.genotype[OFFSET(0)] = 1 AND c.genotype[OFFSET(1)] = 1) AS obs_hom_alt,
    COUNT(*) AS total_samples
  FROM `genomics-public-data.1000_genomes.variants` v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = '17' AND v.start BETWEEN 41196311 AND 41277499
  GROUP BY v.reference_name, v.start, v.`end`, v.reference_bases, alternate_bases, variant_type
),
allele_frequencies AS (
  SELECT
    *,
    ROUND((2 * obs_hom_alt + obs_het) / (2 * total_samples), 4) AS allele_frequency
  FROM variant_counts
),
expected_counts AS (
  SELECT
    *,
    ROUND(total_samples * POW(1 - allele_frequency, 2), 4) AS expected_hom_ref,
    ROUND(2 * total_samples * allele_frequency * (1 - allele_frequency), 4) AS expected_het,
    ROUND(total_samples * POW(allele_frequency, 2), 4) AS expected_hom_alt
  FROM allele_frequencies
),
chi_squared_calc AS (
  SELECT
    *,
    ROUND(
      COALESCE(POW(obs_hom_ref - expected_hom_ref, 2) / NULLIF(expected_hom_ref, 0), 0) +
      COALESCE(POW(obs_het - expected_het, 2) / NULLIF(expected_het, 0), 0) +
      COALESCE(POW(obs_hom_alt - expected_hom_alt, 2) / NULLIF(expected_hom_alt, 0), 0),
      4
    ) AS chi_squared_score
  FROM expected_counts
)
SELECT
  reference_name,
  start,
  `end`,
  reference_bases,
  alternate_bases,
  variant_type,
  chi_squared_score,
  obs_hom_ref AS observed_counts_homozygous_reference_genotypes,
  expected_hom_ref AS expected_counts_homozygous_reference_genotypes,
  obs_het AS observed_counts_heterozygous_genotypes,
  expected_het AS expected_counts_heterozygous_genotypes,
  obs_hom_alt AS observed_counts_homozygous_alternate_genotypes,
  expected_hom_alt AS expected_counts_homozygous_alternate_genotypes,
  allele_frequency AS allele_frequencies
FROM chi_squared_calc;