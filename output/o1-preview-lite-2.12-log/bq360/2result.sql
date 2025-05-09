WITH valid_specializations AS (
  SELECT
    npi,
    specialization
  FROM
    `bigquery-public-data.nppes.npi_optimized`
  CROSS JOIN UNNEST([
    healthcare_provider_taxonomy_1_specialization,
    healthcare_provider_taxonomy_2_specialization,
    healthcare_provider_taxonomy_3_specialization,
    healthcare_provider_taxonomy_4_specialization,
    healthcare_provider_taxonomy_5_specialization,
    healthcare_provider_taxonomy_6_specialization,
    healthcare_provider_taxonomy_7_specialization,
    healthcare_provider_taxonomy_8_specialization,
    healthcare_provider_taxonomy_9_specialization,
    healthcare_provider_taxonomy_10_specialization,
    healthcare_provider_taxonomy_11_specialization,
    healthcare_provider_taxonomy_12_specialization,
    healthcare_provider_taxonomy_13_specialization,
    healthcare_provider_taxonomy_14_specialization,
    healthcare_provider_taxonomy_15_specialization
  ]) AS specialization
  WHERE
    LOWER(provider_business_practice_location_address_city_name) = 'mountain view'
    AND provider_business_practice_location_address_state_name = 'CA'
    AND specialization IS NOT NULL
    AND specialization != ''
),
top_specializations AS (
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_count
  FROM
    valid_specializations
  GROUP BY
    specialization
  ORDER BY
    npi_count DESC
  LIMIT
    10
),
average_npi_count AS (
  SELECT
    AVG(npi_count) AS avg_npi_count
  FROM
    top_specializations
),
specialization_closest_to_average AS (
  SELECT
    specialization,
    npi_count,
    ABS(npi_count - avg_npi_count) AS difference
  FROM
    top_specializations,
    average_npi_count
  ORDER BY
    difference ASC
  LIMIT
    1
)
SELECT
  specialization AS specialization_name,
  npi_count AS count_of_NPIs
FROM
  specialization_closest_to_average;