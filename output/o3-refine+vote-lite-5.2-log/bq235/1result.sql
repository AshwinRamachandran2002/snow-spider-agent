-- Provider with the highest combined average 2014 costs (inpatient + outpatient)
WITH inpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    AVG(average_total_payments) AS avg_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
),
outpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    AVG(average_total_payments) AS avg_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
)
SELECT
  i.provider_id,
  i.provider_name,                         -- name taken from inpatient table
  ROUND(i.avg_inpatient_cost, 2)  AS avg_inpatient_cost,
  ROUND(o.avg_outpatient_cost, 2) AS avg_outpatient_cost,
  ROUND(i.avg_inpatient_cost + o.avg_outpatient_cost, 2) AS combined_avg_cost
FROM inpatient i
JOIN outpatient o
ON i.provider_id = o.provider_id                -- keep providers present in BOTH datasets
ORDER BY combined_avg_cost DESC
LIMIT 1;