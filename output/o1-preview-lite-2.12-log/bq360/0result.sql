WITH taxonomy_unpivoted AS (
  SELECT
    npi.npi,
    tax_code AS taxonomy_code
  FROM
    `bigquery-public-data.nppes.npi_raw` AS npi,
    UNNEST([
      npi.healthcare_provider_taxonomy_code_1,
      npi.healthcare_provider_taxonomy_code_2,
      npi.healthcare_provider_taxonomy_code_3,
      npi.healthcare_provider_taxonomy_code_4,
      npi.healthcare_provider_taxonomy_code_5,
      npi.healthcare_provider_taxonomy_code_6,
      npi.healthcare_provider_taxonomy_code_7,
      npi.healthcare_provider_taxonomy_code_8,
      npi.healthcare_provider_taxonomy_code_9,
      npi.healthcare_provider_taxonomy_code_10,
      npi.healthcare_provider_taxonomy_code_11,
      npi.healthcare_provider_taxonomy_code_12,
      npi.healthcare_provider_taxonomy_code_13,
      npi.healthcare_provider_taxonomy_code_14,
      npi.healthcare_provider_taxonomy_code_15
    ]) AS tax_code
  WHERE
    LOWER(npi.provider_business_practice_location_address_city_name) = 'mountain view'
    AND npi.provider_business_practice_location_address_state_name = 'CA'
    AND tax_code IS NOT NULL
    AND tax_code != ''
),
specialization_counts AS (
  SELECT
    tax.specialization,
    COUNT(DISTINCT t.npi) AS npi_count
  FROM
    taxonomy_unpivoted AS t
  JOIN
    `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS tax
      ON t.taxonomy_code = tax.code
  WHERE
    tax.specialization IS NOT NULL
    AND tax.specialization != ''
  GROUP BY
    tax.specialization
  ORDER BY
    npi_count DESC
  LIMIT 10
),
avg_npi_count AS (
  SELECT
    AVG(npi_count) AS avg_count
  FROM
    specialization_counts
)
SELECT
  specialization AS specialization_name,
  npi_count AS count_of_NPIs
FROM
  specialization_counts
CROSS JOIN
  avg_npi_count
ORDER BY
  ABS(npi_count - avg_count) ASC
LIMIT 1;