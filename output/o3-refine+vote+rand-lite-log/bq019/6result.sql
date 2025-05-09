-- DRG with most discharges in 2014 and weighted‑average total payments
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
  LIMIT 1                       -- DRG with the highest discharge count
),
city_level AS (
  SELECT
    t.drg_definition,
    TRIM(t.provider_city) AS city,
    SUM(t.total_discharges)                                       AS city_discharges,
    SUM(t.total_discharges * t.average_total_payments)            AS weighted_payment_sum
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014` t
  JOIN
    top_drg d
  ON
    t.drg_definition = d.drg_definition
  GROUP BY
    t.drg_definition,
    city
),
top_cities AS (
  SELECT
    drg_definition,
    city,
    city_discharges,
    SAFE_DIVIDE(weighted_payment_sum, city_discharges) AS weighted_avg_total_payments
  FROM
    city_level
  ORDER BY
    city_discharges DESC         -- ranking cities by discharge volume
  LIMIT 3                        -- top three cities
)

SELECT
  drg_definition,
  city,
  city_discharges,
  weighted_avg_total_payments
FROM
  top_cities
ORDER BY
  city_discharges DESC;