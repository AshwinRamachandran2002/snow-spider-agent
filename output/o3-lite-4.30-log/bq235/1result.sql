WITH inpatient AS (
  SELECT
    provider_id,
    AVG(average_total_payments) AS avg_inpatient_pay
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY
    provider_id
),
outpatient AS (
  SELECT
    provider_id,
    AVG(average_total_payments) AS avg_outpatient_pay
  FROM
    `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY
    provider_id
),
combined AS (
  SELECT
    i.provider_id,
    (i.avg_inpatient_pay + o.avg_outpatient_pay) AS combined_avg_cost
  FROM
    inpatient i
  JOIN
    outpatient o
  USING (provider_id)
),
top_provider AS (
  SELECT
    provider_id,
    combined_avg_cost
  FROM
    combined
  ORDER BY
    combined_avg_cost DESC
  LIMIT 1
)
SELECT
  DISTINCT ip.provider_name,
  FORMAT('%.4f', tp.combined_avg_cost) AS combined_average_cost_2014
FROM
  top_provider tp
JOIN
  `bigquery-public-data.cms_medicare.inpatient_charges_2014` ip
ON
  tp.provider_id = ip.provider_id
LIMIT 1;