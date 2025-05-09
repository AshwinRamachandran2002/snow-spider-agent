WITH sample_population AS (
  SELECT
    Sample AS sample,
    Super_Population AS super_population_code
  FROM
    `genomics-public-data.1000_genomes.sample_info`
),

calls_with_population AS (
  SELECT
    v.reference_name,
    v.start AS start,
    v.end AS `end`,
    c.call_set_name AS sample,
    c.genotype,
    sp.super_population_code
  FROM
    `genomics-public-data.1000_genomes.variants` AS v,
    UNNEST(v.call) AS c
  JOIN
    sample_population AS sp
  ON
    c.call_set_name = sp.sample
  WHERE
    v.reference_name = '12'
    AND sp.super_population_code IN ('EAS', 'EUR')
),

genotype_counts AS (
  SELECT
    reference_name,
    start,
    `end`,
    sample,
    super_population_code,
    CASE
      WHEN ARRAY_LENGTH(genotype) = 2
        AND genotype[SAFE_OFFSET(0)] != -1
        AND genotype[SAFE_OFFSET(1)] != -1 THEN
        genotype[SAFE_OFFSET(0)] + genotype[SAFE_OFFSET(1)]
      ELSE NULL
    END AS num_alt_alleles
  FROM
    calls_with_population
),

allele_counts AS (
  SELECT
    reference_name,
    start,
    `end`,
    super_population_code,
    SUM(num_alt_alleles) AS alt_allele_count,
    (COUNTIF(num_alt_alleles IS NOT NULL) * 2 - SUM(num_alt_alleles)) AS ref_allele_count,
    COUNTIF(num_alt_alleles IS NOT NULL) * 2 AS total_alleles
  FROM
    genotype_counts
  GROUP BY
    reference_name,
    start,
    `end`,
    super_population_code
),

allele_counts_pivot AS (
  SELECT
    reference_name,
    start,
    `end`,
    MAX(IF(super_population_code = 'EAS', alt_allele_count, NULL)) AS cases_alt_allele_count,
    MAX(IF(super_population_code = 'EAS', ref_allele_count, NULL)) AS cases_ref_allele_count,
    MAX(IF(super_population_code = 'EUR', alt_allele_count, NULL)) AS controls_alt_allele_count,
    MAX(IF(super_population_code = 'EUR', ref_allele_count, NULL)) AS controls_ref_allele_count
  FROM
    allele_counts
  GROUP BY
    reference_name,
    start,
    `end`
),

chi_squared_calculation AS (
  SELECT
    reference_name,
    start,
    `end`,
    cases_alt_allele_count AS a,
    controls_alt_allele_count AS b,
    cases_ref_allele_count AS c,
    controls_ref_allele_count AS d
  FROM
    allele_counts_pivot
  WHERE
    cases_alt_allele_count IS NOT NULL AND controls_alt_allele_count IS NOT NULL 
    AND cases_ref_allele_count IS NOT NULL AND controls_ref_allele_count IS NOT NULL
    AND (cases_alt_allele_count + controls_alt_allele_count + cases_ref_allele_count + controls_ref_allele_count) > 0
),

chi_squared_values AS (
  SELECT
    reference_name,
    start,
    `end`,
    a,
    b,
    c,
    d,
    (a + b + c + d) AS n,
    ((a + b) * (a + c)) / (a + b + c + d) AS E_a,
    ((a + b) * (b + d)) / (a + b + c + d) AS E_b,
    ((c + d) * (a + c)) / (a + b + c + d) AS E_c,
    ((c + d) * (b + d)) / (a + b + c + d) AS E_d
  FROM
    chi_squared_calculation
),

filtered_variants AS (
  SELECT
    reference_name,
    start,
    `end`,
    a,
    b,
    c,
    d,
    n,
    E_a,
    E_b,
    E_c,
    E_d
  FROM
    chi_squared_values
  WHERE
    E_a >= 5 AND E_b >= 5 AND E_c >= 5 AND E_d >= 5
),

chi_squared_scores AS (
  SELECT
    reference_name,
    start,
    `end`,
    ((POWER(ABS(a*d - b*c) - (n/2), 2)) * n) / ((a + b)*(c + d)*(a + c)*(b + d)) AS chi_squared_score
  FROM
    filtered_variants
)

SELECT
  start,
  `end`,
  ROUND(chi_squared_score, 4) AS chi_squared_score
FROM
  chi_squared_scores
WHERE
  chi_squared_score >= 29.71679
ORDER BY
  chi_squared_score DESC