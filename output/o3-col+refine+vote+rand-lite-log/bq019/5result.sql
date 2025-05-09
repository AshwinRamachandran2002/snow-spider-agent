-- 1) Identify the DRG with the most discharges in 2014
-- 2) Find the three cities with the most discharges for that DRG
-- 3) For each of those cities, compute the weighted-average total payment
WITH drg_rank AS (
  SELECT
    drg_definition,
    SUM(total_discharges) AS total_discharges_all
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY total_discharges_all DESC
  LIMIT 1
),
top_cities AS (
  SELECT
    provider_city,
    SUM(total_discharges) AS city_total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition = (SELECT drg_definition FROM drg_rank)
  GROUP BY provider_city
  ORDER BY city_total_discharges DESC
  LIMIT 3
)
SELECT
  (SELECT drg_definition FROM drg_rank) AS drg_definition_with_most_discharges,
  tc.provider_city,
  tc.city_total_discharges,
  SUM(ic.total_discharges * ic.average_total_payments)
/ SUM(ic.total_discharges)          AS weighted_avg_total_payments
FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS ic
JOIN top_cities AS tc
  ON ic.provider_city = tc.provider_city
WHERE ic.drg_definition = (SELECT drg_definition FROM drg_rank)
GROUP BY
  drg_definition_with_most_discharges,
  tc.provider_city,
  tc.city_total_discharges
ORDER BY tc.city_total_discharges DESC;