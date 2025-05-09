WITH inpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    AVG(average_total_payments) AS inpatient_avg_cost
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY
    provider_id
),
outpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    AVG(average_total_payments) AS outpatient_avg_cost
  FROM
    `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY
    provider_id
)
SELECT
  i.provider_id,
  COALESCE(i.provider_name, o.provider_name) AS provider_name,
  i.inpatient_avg_cost,
  o.outpatient_avg_cost,
  (i.inpatient_avg_cost + o.outpatient_avg_cost) AS combined_avg_cost
FROM
  inpatient i
JOIN
  outpatient o
USING (provider_id)
ORDER BY
  combined_avg_cost DESC
LIMIT 1;