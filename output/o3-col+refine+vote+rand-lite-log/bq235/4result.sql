SELECT
  npi,
  ANY_VALUE(nppes_provider_last_org_name) AS provider_last_org_name,
  ANY_VALUE(nppes_provider_first_name)    AS provider_first_name,
  SUM(average_medicare_payment_amt)       AS total_outpatient_like_cost,
  SUM(average_medicare_standard_amt)      AS total_inpatient_like_cost,
  SUM(average_medicare_payment_amt + average_medicare_standard_amt) AS combined_average_cost
FROM `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
GROUP BY npi
ORDER BY combined_average_cost DESC
LIMIT 1;