-- 1. pick the DRG definition with the largest overall number of discharges
WITH top_drg AS (
  SELECT
    drg_definition,
    SUM(total_discharges) AS total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY total_discharges DESC
  LIMIT 1
),

-- 2. for that DRG definition, compute discharges and the weighted‑average
--    total payments (weighted by discharges) for every city
city_metrics AS (
  SELECT
    ic.provider_city,
    SUM(ic.total_discharges)                         AS city_total_discharges,
    SUM(ic.total_discharges * ic.average_total_payments) AS weighted_payment_sum
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS ic
  JOIN top_drg AS td
  ON  ic.drg_definition = td.drg_definition
  GROUP BY ic.provider_city
),

-- 3. pick the three cities with the most discharges for that DRG definition
top_3_cities AS (
  SELECT
    provider_city,
    city_total_discharges,
    weighted_payment_sum / city_total_discharges AS weighted_avg_total_payments
  FROM city_metrics
  ORDER BY city_total_discharges DESC
  LIMIT 3
)

-- 4. final result
SELECT
  (SELECT drg_definition FROM top_drg) AS drg_definition_with_most_discharges,
  provider_city                        AS city,
  weighted_avg_total_payments
FROM top_3_cities
ORDER BY city_total_discharges DESC;