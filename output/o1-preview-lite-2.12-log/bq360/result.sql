WITH top_specializations AS (
  SELECT
    hpt.specialization AS specialization_name,
    COUNT(DISTINCT npi.npi) AS count_of_NPIs
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
    ]) AS taxonomy_code
  JOIN
    `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS hpt
  ON
    taxonomy_code = hpt.code
  WHERE
    UPPER(npi.provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND npi.provider_business_practice_location_address_state_name = 'CA'
    AND taxonomy_code IS NOT NULL
    AND hpt.specialization IS NOT NULL
    AND hpt.specialization != ''
  GROUP BY
    hpt.specialization
  ORDER BY
    count_of_NPIs DESC
  LIMIT 10
), avg_npi_count AS (
  SELECT AVG(count_of_NPIs) AS avg_npi_count FROM top_specializations
)
SELECT
  specialization_name,
  count_of_NPIs
FROM
  top_specializations,
  avg_npi_count
ORDER BY
  ABS(count_of_NPIs - avg_npi_count.avg_npi_count)
LIMIT 1;