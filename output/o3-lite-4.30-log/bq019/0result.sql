WITH drg_max AS (
  -- Identify the DRG with the highest total discharges
  SELECT
    drg_definition
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY SUM(total_discharges) DESC
  LIMIT 1
),
city_metrics AS (
  -- For that DRG, compute city‑level discharge counts and weighted avg payments
  SELECT
    ic.drg_definition,
    ic.provider_city,
    ic.provider_state,
    SUM(ic.total_discharges) AS city_discharges,
    SUM(ic.total_discharges * ic.average_total_payments)
      / SUM(ic.total_discharges) AS weighted_avg_total_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS ic
  JOIN drg_max dm
    ON ic.drg_definition = dm.drg_definition
  GROUP BY ic.drg_definition, ic.provider_city, ic.provider_state
),
top_three AS (
  SELECT
    drg_definition,
    provider_city,
    provider_state,
    ROUND(weighted_avg_total_payments, 4) AS weighted_avg_total_payments,
    ROW_NUMBER() OVER (ORDER BY city_discharges DESC) AS rn
  FROM city_metrics
)
SELECT
  drg_definition,
  provider_city,
  provider_state,
  weighted_avg_total_payments
FROM top_three
WHERE rn <= 3
ORDER BY rn;