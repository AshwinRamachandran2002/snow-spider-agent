-- DRG with the most discharges in 2014 and, for that DRG,
-- the three cities with the largest discharge counts along with
-- their weighted-average total payments
WITH top_drg AS (
  SELECT drg_definition
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY SUM(total_discharges) DESC
  LIMIT 1
),
city_aggregates AS (
  SELECT
    provider_city,
    SUM(total_discharges)                                       AS city_discharges,
    SUM(average_total_payments * total_discharges)              AS pay_weighted
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` t
  JOIN top_drg d
    ON t.drg_definition = d.drg_definition
  GROUP BY provider_city
),
top_three_cities AS (
  SELECT *
  FROM city_aggregates
  ORDER BY city_discharges DESC
  LIMIT 3
)
SELECT
  (SELECT drg_definition FROM top_drg)                          AS drg_definition,
  provider_city,
  city_discharges,
  ROUND(pay_weighted / city_discharges, 2)                      AS weighted_avg_total_payments
FROM top_three_cities
ORDER BY city_discharges DESC;