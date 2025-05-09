-- 1) Find the DRG definition with the largest overall number of discharges
WITH drg_rank AS (
  SELECT
    drg_definition,
    SUM(total_discharges) AS total_discharges
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY
    drg_definition
  ORDER BY
    total_discharges DESC
  LIMIT 1        -- highest‑volume DRG definition
),

-- 2) Within that DRG, rank cities by total discharges and keep the top‑3
top_cities AS (
  SELECT
    ic.provider_city        AS city,
    SUM(ic.total_discharges) AS city_discharges
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS ic
    JOIN drg_rank AS dr USING (drg_definition)
  GROUP BY
    city
  ORDER BY
    city_discharges DESC
  LIMIT 3
),

-- 3) For each of those cities, compute the weighted average total payments
--    (weighted by the number of discharges)
city_weighted_payments AS (
  SELECT
    ic.provider_city                     AS city,
    SUM(ic.total_discharges * ic.average_total_payments)
      / SUM(ic.total_discharges)        AS weighted_avg_total_payments,
    SUM(ic.total_discharges)            AS total_city_discharges
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS ic
    JOIN drg_rank   AS dr USING (drg_definition)
    JOIN top_cities AS tc ON ic.provider_city = tc.city
  GROUP BY
    city
)

-- 4) Final answer: DRG with highest volume and the weighted averages for the
--    three highest‑volume cities within it
SELECT
  drg_definition                              AS highest_volume_drg_definition,
  city,
  total_city_discharges,
  weighted_avg_total_payments
FROM
  city_weighted_payments
CROSS JOIN
  drg_rank
ORDER BY
  total_city_discharges DESC;