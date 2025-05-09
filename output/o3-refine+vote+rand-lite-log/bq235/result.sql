-- Provider with the highest combined (inpatient + outpatient) average total payments in 2014
WITH per_source_avg AS (
  -- Average total payments per provider for 2014 inpatient services
  SELECT
    provider_id,
    provider_name,
    AVG(average_total_payments) AS avg_payments
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY
    provider_id,
    provider_name
  
  UNION ALL
  
  -- Average total payments per provider for 2014 outpatient services
  SELECT
    provider_id,
    provider_name,
    AVG(average_total_payments) AS avg_payments
  FROM
    `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY
    provider_id,
    provider_name
)

SELECT
  provider_id,
  provider_name,
  SUM(avg_payments) AS combined_average_total_payments
FROM
  per_source_avg
GROUP BY
  provider_id,
  provider_name
ORDER BY
  combined_average_total_payments DESC
LIMIT 1;