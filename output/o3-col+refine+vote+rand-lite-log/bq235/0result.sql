SELECT
  npi,
  nppes_provider_last_org_name,
  nppes_provider_first_name,
  SUM(CASE WHEN place_of_service = 'O' THEN average_medicare_allowed_amt ELSE 0 END) AS outpatient_avg_allowed,
  SUM(CASE WHEN place_of_service = 'F' THEN average_medicare_allowed_amt ELSE 0 END) AS inpatient_avg_allowed,
  SUM(average_medicare_allowed_amt) AS combined_avg_allowed
FROM `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
GROUP BY
  npi,
  nppes_provider_last_org_name,
  nppes_provider_first_name
ORDER BY
  combined_avg_allowed DESC
LIMIT 1;