-- DRG definition with the most total discharges in 2014
-- and the weighted‑average total payments (weighted by discharges)
-- for the three cities with the highest discharge counts for that DRG
WITH drg_tot AS (                           -- total discharges per DRG
  SELECT
    drg_definition,
    SUM(total_discharges) AS total_discharges
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY
    drg_definition
),
max_drg AS (                                -- the single DRG with the most discharges
  SELECT
    drg_definition
  FROM
    drg_tot
  ORDER BY
    total_discharges DESC
  LIMIT 1
),
drg_city AS (                               -- discharges & payment totals for that DRG by city
  SELECT
    UPPER(provider_city)                           AS city,
    SUM(total_discharges)                          AS city_discharges,
    SUM(total_discharges * average_total_payments) AS weighted_pay_total
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014` ic
  JOIN
    max_drg md
  ON
    ic.drg_definition = md.drg_definition
  GROUP BY
    city
),
top_cities AS (                             -- three cities with the most discharges
  SELECT
    city,
    city_discharges,
    weighted_pay_total / city_discharges AS weighted_avg_total_payments
  FROM
    drg_city
  ORDER BY
    city_discharges DESC
  LIMIT 3
)
SELECT
  (SELECT drg_definition FROM max_drg) AS drg_definition_with_max_discharges,
  city,
  weighted_avg_total_payments
FROM
  top_cities
ORDER BY
  city_discharges DESC;