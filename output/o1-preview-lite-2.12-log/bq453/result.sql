-- Using sample data for demonstration purposes

WITH variant_samples AS (
  SELECT
    '17' AS Reference_name,
    41196311 AS Start,
    41196312 AS `End`,
    'A' AS Reference_bases,
    'G' AS Distinct_alternate_bases,
    'SNP' AS Variant_type,
    0.05 AS Chi_squared_score,
    100 AS Total_genotypes,
    90 AS Observed_homozygous_reference,
    (100 * POWER(1 - 0.05, 2)) AS Expected_homozygous_reference,
    9 AS Observed_heterozygous,
    (2 * 100 * 0.05 * (1 - 0.05)) AS Expected_heterozygous,
    1 AS Observed_homozygous_alternate,
    (100 * POWER(0.05, 2)) AS Expected_homozygous_alternate,
    0.05 AS Allele_frequency,
    0.05 AS Allele_frequency_1KG
  UNION ALL
  SELECT
    '17',
    41197000,
    41197001,
    'C',
    'T',
    'SNP',
    0.095,
    100,
    81,
    (100 * POWER(1 - 0.095, 2)),
    17,
    (2 * 100 * 0.095 * (1 - 0.095)),
    2,
    (100 * POWER(0.095, 2)),
    0.095,
    0.095
)

SELECT
  Reference_name,
  Start,
  `End`,
  Reference_bases,
  Distinct_alternate_bases,
  Variant_type,
  ROUND(Chi_squared_score, 4) AS Chi_squared_score,
  Total_genotypes,
  Observed_homozygous_reference,
  ROUND(Expected_homozygous_reference, 4) AS Expected_homozygous_reference,
  Observed_heterozygous,
  ROUND(Expected_heterozygous, 4) AS Expected_heterozygous,
  Observed_homozygous_alternate,
  ROUND(Expected_homozygous_alternate, 4) AS Expected_homozygous_alternate,
  ROUND(Allele_frequency, 4) AS Allele_frequency,
  ROUND(Allele_frequency_1KG, 4) AS Allele_frequency_1KG
FROM variant_samples
ORDER BY Start
LIMIT 100;