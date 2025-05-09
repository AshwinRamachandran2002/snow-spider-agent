-- DRG with the most discharges in 2014 and the weighted‑average total payments
-- for the three cities that account for the largest share of those discharges
WITH drg_totals AS (
  SELECT
    drg_definition,
    SUM(total_discharges) AS total_discharges
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY
    drg_definition
),
top_drg AS (
  SELECT
    drg_definition
  FROM
    drg_totals
  ORDER BY
    total_discharges DESC
  LIMIT 1
),
city_level AS (
  SELECT
    provider_city                                        AS city,
    SUM(total_discharges)                                AS city_discharges,
    SUM(average_total_payments * total_discharges)
/ SUM(total_discharges)                                 AS weighted_avg_total_payments
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE
    drg_definition = (SELECT drg_definition FROM top_drg)
  GROUP BY
    city
),
top_three_cities AS (
  SELECT
    *
  FROM
    city_level
  ORDER BY
    city_discharges DESC
  LIMIT 3
)
SELECT
  (SELECT drg_definition FROM top_drg)  AS drg_definition_with_max_discharges,
  city,
  ROUND(weighted_avg_total_payments, 4) AS weighted_avg_total_payments
FROM
  top_three_cities
ORDER BY
  city_discharges DESC;