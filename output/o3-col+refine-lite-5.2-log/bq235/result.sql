-- Highest combined average (Outpatient + Inpatient) Medicare payment in CY 2014
WITH outpatient AS (
  SELECT
    provider_id,
    AVG(average_total_payments) AS avg_outpatient_payment_2014
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
),
inpatient AS (
  SELECT
    provider_id,
    AVG(average_total_payments) AS avg_inpatient_payment_2014
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
),
combined AS (
  SELECT
    o.provider_id,
    o.avg_outpatient_payment_2014,
    i.avg_inpatient_payment_2014,
    (o.avg_outpatient_payment_2014 + i.avg_inpatient_payment_2014) AS combined_avg_cost_2014
  FROM outpatient AS o
  JOIN inpatient  AS i USING (provider_id)
),
provider_name AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
)
SELECT
  c.provider_id,
  p.provider_name,
  c.avg_outpatient_payment_2014,
  c.avg_inpatient_payment_2014,
  c.combined_avg_cost_2014
FROM combined AS c
JOIN provider_name AS p USING (provider_id)
ORDER BY combined_avg_cost_2014 DESC, provider_id
LIMIT 1;