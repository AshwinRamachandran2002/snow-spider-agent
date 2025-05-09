WITH data_2014 AS (
  SELECT
    drg_definition,
    provider_city,
    total_discharges,
    average_total_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
),
top_drg AS (        -- DRG with the highest overall discharges
  SELECT drg_definition
  FROM data_2014
  GROUP BY drg_definition
  ORDER BY SUM(total_discharges) DESC
  LIMIT 1
),
top_cities AS (     -- Three cities with most discharges for that DRG
  SELECT provider_city
  FROM data_2014
  WHERE drg_definition IN (SELECT drg_definition FROM top_drg)
  GROUP BY provider_city
  ORDER BY SUM(total_discharges) DESC
  LIMIT 3
)
SELECT
  d.drg_definition,
  d.provider_city,
  ROUND(SUM(d.total_discharges * d.average_total_payments) / SUM(d.total_discharges), 4) AS weighted_avg_total_payments,
  SUM(d.total_discharges) AS total_discharges_city
FROM data_2014 d
JOIN top_drg     td ON d.drg_definition = td.drg_definition
JOIN top_cities  tc ON d.provider_city  = tc.provider_city
GROUP BY d.drg_definition, d.provider_city
ORDER BY total_discharges_city DESC;