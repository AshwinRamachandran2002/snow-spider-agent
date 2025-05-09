-- provider with the highest combined (inpatient + outpatient) average total payments in 2014
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
    i.provider_id,
    COALESCE(i.provider_name, o.provider_name) AS provider_name,
    i.avg_inpatient_cost,
    o.avg_outpatient_cost,
    (i.avg_inpatient_cost + o.avg_outpatient_cost) AS combined_avg_cost
  FROM inpatient i
  JOIN outpatient o USING (provider_id)
)
SELECT
  provider_id,
  provider_name,
  avg_inpatient_cost,
  avg_outpatient_cost,
  combined_avg_cost
FROM combined
ORDER BY combined_avg_cost DESC
LIMIT 1;