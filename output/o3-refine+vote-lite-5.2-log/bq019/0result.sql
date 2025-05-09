-- DRG with the most discharges in 2014 and the weighted‑average total payments
-- for the three cities that account for the largest share of those discharges
WITH drg_rank AS (
  SELECT
    drg_definition,
    SUM(total_discharges) AS drg_total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
),
top_drg AS (
  SELECT drg_definition
  FROM drg_rank
  ORDER BY drg_total_discharges DESC
  LIMIT 1
),
city_agg AS (
  SELECT
    provider_city                    AS city,
    SUM(total_discharges)            AS city_total_discharges,
    -- weighted average = Σ(payments * discharges) / Σ(discharges)
    SUM(average_total_payments * total_discharges)
      / SUM(total_discharges)        AS weighted_avg_total_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition = (SELECT drg_definition FROM top_drg)
  GROUP BY provider_city
),
top_cities AS (
  SELECT *
  FROM city_agg
  ORDER BY city_total_discharges DESC
  LIMIT 3
)
SELECT
  (SELECT drg_definition FROM top_drg)         AS drg_definition_with_max_discharges,
  city,
  city_total_discharges,
  weighted_avg_total_payments
FROM top_cities
ORDER BY city_total_discharges DESC, city;