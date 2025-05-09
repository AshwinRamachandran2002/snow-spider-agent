-- 1) Find the DRG definition with the most total discharges in 2014
-- 2) For that DRG, identify the three cities with the greatest number of discharges
-- 3) For each of those cities, compute the weighted‑average total payments
--    (weight = total_discharges), rounded to 4 decimal places

WITH drg_totals AS (
  SELECT
    drg_definition,
    SUM(total_discharges) AS drg_total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
),
top_drg AS (
  SELECT
    drg_definition
  FROM drg_totals
  ORDER BY drg_total_discharges DESC
  LIMIT 1
),
drg_records AS (
  -- all records that belong to the single, highest‑volume DRG
  SELECT
    provider_city AS city,
    total_discharges,
    average_total_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition = (SELECT drg_definition FROM top_drg)
),
city_discharges AS (
  SELECT
    city,
    SUM(total_discharges) AS city_total_discharges
  FROM drg_records
  GROUP BY city
),
top_cities AS (
  SELECT
    city
  FROM city_discharges
  ORDER BY city_total_discharges DESC
  LIMIT 3
),
city_weighted_payments AS (
  SELECT
    r.city,
    SUM(r.average_total_payments * r.total_discharges) / SUM(r.total_discharges) AS weighted_avg_total_payments,
    SUM(r.total_discharges)                                    AS city_total_discharges
  FROM drg_records r
  JOIN top_cities t
    ON r.city = t.city
  GROUP BY r.city
)
SELECT
  (SELECT drg_definition FROM top_drg)                       AS drg_definition_with_most_discharges,
  city,
  ROUND(weighted_avg_total_payments, 4)                      AS weighted_avg_total_payments
FROM city_weighted_payments
ORDER BY city_total_discharges DESC;