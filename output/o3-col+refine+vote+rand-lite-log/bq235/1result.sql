-- Provider with the highest combined average (outpatient + inpatient) Medicare allowed amount in 2014
SELECT
  npi,
  nppes_provider_last_org_name  AS last_name,
  nppes_provider_first_name     AS first_name,
  SUM(CASE WHEN place_of_service = 'O' THEN average_medicare_allowed_amt ELSE 0 END) AS outpatient_avg_allowed,
  SUM(CASE WHEN place_of_service = 'F' THEN average_medicare_allowed_amt ELSE 0 END) AS inpatient_avg_allowed,
  SUM(average_medicare_allowed_amt)                                                   AS combined_avg_allowed
FROM `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
GROUP BY npi, last_name, first_name
ORDER BY combined_avg_allowed DESC
LIMIT 1;