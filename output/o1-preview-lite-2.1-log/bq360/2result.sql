WITH top_specializations AS (
  SELECT
    taxonomy.`specialization`,
    COUNT(*) AS `specialist_count`
  FROM `bigquery-public-data.nppes.npi_raw` AS npi
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS taxonomy
    ON npi.`healthcare_provider_taxonomy_code_1` = taxonomy.`code`
  WHERE LOWER(npi.`provider_business_practice_location_address_city_name`) = 'mountain view'
    AND npi.`provider_business_mailing_address_state_name` = 'CA'
  GROUP BY taxonomy.`specialization`
  ORDER BY `specialist_count` DESC
  LIMIT 10
), avg_count AS (
  SELECT AVG(`specialist_count`) AS `avg_specialist_count`
  FROM top_specializations
)
SELECT `specialization`, `specialist_count`
FROM top_specializations, avg_count
ORDER BY ABS(`specialist_count` - `avg_specialist_count`) ASC
LIMIT 1;