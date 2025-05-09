SELECT specialization, specialist_count
FROM (
  SELECT taxonomy.specialization, COUNT(*) AS specialist_count
  FROM `bigquery-public-data.nppes.npi_raw` AS npi_raw
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS taxonomy
    ON npi_raw.healthcare_provider_taxonomy_code_1 = taxonomy.code
  WHERE UPPER(npi_raw.provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND npi_raw.provider_business_practice_location_address_state_name = 'CA'
    AND taxonomy.specialization IS NOT NULL
    AND taxonomy.specialization != ''
  GROUP BY taxonomy.specialization
  ORDER BY specialist_count DESC
  LIMIT 10
) AS top_specializations
CROSS JOIN (
  SELECT AVG(specialist_count) AS avg_count
  FROM (
    SELECT COUNT(*) AS specialist_count
    FROM `bigquery-public-data.nppes.npi_raw` AS npi_raw
    JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS taxonomy
      ON npi_raw.healthcare_provider_taxonomy_code_1 = taxonomy.code
    WHERE UPPER(npi_raw.provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
      AND npi_raw.provider_business_practice_location_address_state_name = 'CA'
      AND taxonomy.specialization IS NOT NULL
      AND taxonomy.specialization != ''
    GROUP BY taxonomy.specialization
    ORDER BY specialist_count DESC
    LIMIT 10
  )
) AS avg_specialist_count
ORDER BY ABS(specialist_count - avg_specialist_count.avg_count) ASC
LIMIT 1;