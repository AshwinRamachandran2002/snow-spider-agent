WITH top_drg AS (
  -- 1. Identify the DRG definition with the greatest total discharges in 2014
  SELECT drg_definition
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY SUM(total_discharges) DESC
  LIMIT 1
),
city_aggregates AS (
  -- 2. For every city/DRG pair, compute total discharges and the weighted-average payment
  SELECT
    provider_city,
    drg_definition,
    SUM(total_discharges) AS city_total_discharges,
    SUM(average_total_payments * total_discharges) / SUM(total_discharges) AS weighted_avg_total_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_city, drg_definition
)
-- 3. Keep only the rows for the highest-volume DRG and return the top 3 cities
SELECT
  td.drg_definition AS highest_volume_drg,
  ca.provider_city,
  ca.city_total_discharges,
  ca.weighted_avg_total_payments
FROM top_drg AS td
JOIN city_aggregates AS ca
  ON ca.drg_definition = td.drg_definition
ORDER BY ca.city_total_discharges DESC
LIMIT 3;