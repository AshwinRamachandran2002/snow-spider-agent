-- DRG with the most discharges in 2014 and, for that DRG,
-- the three cities with the largest discharge counts together
-- with their weighted-average total payments
WITH top_drg AS (
  SELECT
    drg_definition
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY SUM(total_discharges) DESC
  LIMIT 1
),
city_stats AS (
  SELECT
    t.provider_city,
    SUM(t.total_discharges) AS city_discharges,
    SUM(t.average_total_payments * t.total_discharges)
      / SUM(t.total_discharges) AS weighted_avg_total_payment
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS t
  JOIN top_drg USING (drg_definition)
  GROUP BY t.provider_city
)
SELECT
  (SELECT drg_definition FROM top_drg) AS drg_definition,
  provider_city,
  city_discharges,
  weighted_avg_total_payment
FROM city_stats
ORDER BY city_discharges DESC
LIMIT 3;