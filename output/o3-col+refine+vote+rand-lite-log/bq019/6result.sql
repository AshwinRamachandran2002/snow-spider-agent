WITH top_drg AS (
  SELECT
    drg_definition,
    SUM(total_discharges) AS total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY total_discharges DESC
  LIMIT 1
),
city_stats AS (
  SELECT
    ic.provider_city,
    SUM(ic.total_discharges) AS city_discharges,
    SUM(ic.total_discharges * ic.average_total_payments)
/   SUM(ic.total_discharges) AS weighted_avg_total_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS ic
  JOIN top_drg td
  ON  ic.drg_definition = td.drg_definition
  GROUP BY ic.provider_city
)
SELECT
  (SELECT drg_definition FROM top_drg) AS drg_definition_with_max_discharges,
  provider_city,
  city_discharges,
  weighted_avg_total_payments
FROM city_stats
ORDER BY city_discharges DESC
LIMIT 3;