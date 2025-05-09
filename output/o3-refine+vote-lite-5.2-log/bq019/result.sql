-- 1) Find the DRG definition with the greatest overall number of discharges
WITH drg_ranking AS (
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
    drg_ranking
  ORDER BY
    total_discharges DESC
  LIMIT 1
),

-- 2) Within that DRG definition, identify the three cities with the most discharges
city_ranking AS (
  SELECT
    provider_city,
    SUM(total_discharges) AS city_discharges
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014` ic
  JOIN
    top_drg td
  ON
    ic.drg_definition = td.drg_definition
  GROUP BY
    provider_city
),
top_cities AS (
  SELECT
    provider_city
  FROM
    city_ranking
  ORDER BY
    city_discharges DESC
  LIMIT 3
),

-- 3) For those cities compute the weighted‑average total payments
weighted_city_payments AS (
  SELECT
    ic.provider_city,
    SUM(ic.average_total_payments * ic.total_discharges)
      / SUM(ic.total_discharges)      AS weighted_avg_total_payments
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014` ic
  JOIN
    top_drg    td ON ic.drg_definition = td.drg_definition
  JOIN
    top_cities tc ON ic.provider_city   = tc.provider_city
  GROUP BY
    ic.provider_city
)

-- Final answer
SELECT
  td.drg_definition                                   AS highest_discharge_drg_definition,
  wcp.provider_city                                   AS city,
  wcp.weighted_avg_total_payments
FROM
  weighted_city_payments wcp
CROSS JOIN
  top_drg td
ORDER BY
  wcp.weighted_avg_total_payments DESC;