WITH inpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    AVG(average_total_payments) AS inpatient_avg_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
),
outpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    AVG(average_total_payments) AS outpatient_avg_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
),
combined AS (
  SELECT
    COALESCE(i.provider_id, o.provider_id) AS provider_id,
    COALESCE(i.provider_name, o.provider_name) AS provider_name,
    COALESCE(i.inpatient_avg_cost, 0) AS inpatient_avg_cost,
    COALESCE(o.outpatient_avg_cost, 0) AS outpatient_avg_cost,
    COALESCE(i.inpatient_avg_cost, 0) + COALESCE(o.outpatient_avg_cost, 0) AS combined_avg_cost
  FROM inpatient i
  FULL OUTER JOIN outpatient o
  ON i.provider_id = o.provider_id
)
SELECT
  provider_id,
  provider_name,
  combined_avg_cost
FROM combined
ORDER BY combined_avg_cost DESC
LIMIT 1;