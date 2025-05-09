WITH drg_totals AS (
  -- 1️⃣  Total discharges by DRG
  SELECT
    drg_definition,
    SUM(total_discharges) AS total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
),
max_drg AS (
  -- 2️⃣  DRG with the greatest number of discharges
  SELECT drg_definition
  FROM drg_totals
  ORDER BY total_discharges DESC
  LIMIT 1
),
city_totals AS (
  -- 3️⃣  Top‑3 cities (by discharges) for that DRG
  SELECT
    provider_city,
    SUM(total_discharges) AS city_total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition = (SELECT drg_definition FROM max_drg)
  GROUP BY provider_city
  ORDER BY city_total_discharges DESC
  LIMIT 3
)
-- 4️⃣  Weighted‑average total payments for each of those cities
SELECT
  (SELECT drg_definition FROM max_drg)                           AS drg_definition_with_max_discharges,
  ic.provider_city                                               AS city,
  ROUND(SUM(ic.average_total_payments * ic.total_discharges)
/       SUM(ic.total_discharges), 4)                             AS weighted_avg_total_payments
FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`  AS ic
JOIN city_totals  AS ct
  ON ic.provider_city = ct.provider_city
WHERE ic.drg_definition = (SELECT drg_definition FROM max_drg)
GROUP BY city
ORDER BY weighted_avg_total_payments DESC;