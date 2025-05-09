SELECT
  `npi`,
  CONCAT(`nppes_provider_first_name`, ' ', `nppes_provider_last_org_name`) AS provider_full_name,
  (`average_submitted_chrg_amt` + `average_medicare_payment_amt`)          AS combined_avg_cost
FROM
  `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
ORDER BY
  combined_avg_cost DESC
LIMIT 1;