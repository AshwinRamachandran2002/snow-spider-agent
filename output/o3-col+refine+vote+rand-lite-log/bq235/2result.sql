SELECT
  npi,
  nppes_provider_last_org_name AS last_name_or_org,
  nppes_provider_first_name    AS first_name,
  SUM(average_medicare_allowed_amt) AS highest_combined_avg_allowed_amt
FROM `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
WHERE place_of_service IN ('O', 'F')
GROUP BY npi, last_name_or_org, first_name
ORDER BY highest_combined_avg_allowed_amt DESC
LIMIT 1;