-- Provider with highest combined average (out‑ + in‑patient) payments in 2014
WITH outpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    AVG(average_total_payments) AS avg_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
),
inpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    AVG(average_total_payments) AS avg_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
),
combined AS (
  SELECT
    o.provider_id,
    COALESCE(o.provider_name, i.provider_name) AS provider_name,
    o.avg_outpatient_cost,
    i.avg_inpatient_cost,
    (o.avg_outpatient_cost + i.avg_inpatient_cost) AS combined_avg_cost
  FROM outpatient o
  JOIN inpatient  i USING (provider_id)
)
SELECT
  provider_id,
  provider_name,
  avg_outpatient_cost,
  avg_inpatient_cost,
  combined_avg_cost
FROM combined
ORDER BY combined_avg_cost DESC
LIMIT 1;