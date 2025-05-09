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
    AVG(average_total_payments) AS avg_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
),
combined AS (
  SELECT
    i.provider_name,
    ROUND(i.avg_inpatient_cost + o.avg_outpatient_cost, 4) AS combined_average_cost_2014
  FROM inpatient i
  JOIN outpatient o
  USING (provider_id)
)
SELECT
  provider_name,
  combined_average_cost_2014
FROM combined
ORDER BY combined_average_cost_2014 DESC
LIMIT 1;