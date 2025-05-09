-- Provider with the highest combined 2014 average cost (allowed + submitted + payment + standardized)
WITH provider_totals AS (
  SELECT
    npi,
    ANY_VALUE(nppes_provider_last_org_name)  AS provider_last_org_name,
    ANY_VALUE(nppes_provider_first_name)     AS provider_first_name,
    SUM(
        average_medicare_allowed_amt +
        average_submitted_chrg_amt +
        average_medicare_payment_amt +
        average_medicare_standard_amt
    ) AS combined_avg_cost
  FROM `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
  GROUP BY npi
)
SELECT
  npi,
  provider_last_org_name,
  provider_first_name,
  combined_avg_cost
FROM provider_totals
ORDER BY combined_avg_cost DESC
LIMIT 1;