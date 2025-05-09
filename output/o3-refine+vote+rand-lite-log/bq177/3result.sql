-- yearly inpatient & outpatient average costs for the provider with the
-- highest total inpatient Medicare cost (2011‑2015)

WITH inpatient_raw AS (
  -- all inpatient rows 2011‑2015
  SELECT
    _TABLE_SUFFIX            AS yr,
    provider_id,
    average_medicare_payments,
    total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2015'
),
provider_totals AS (
  -- total inpatient cost across 2011‑2015 for every provider
  SELECT
    provider_id,
    SUM(average_medicare_payments * total_discharges) AS total_inpatient_cost
  FROM inpatient_raw
  GROUP BY provider_id
),
top_provider AS (
  -- provider with the highest 5‑year inpatient cost
  SELECT provider_id
  FROM provider_totals
  ORDER BY total_inpatient_cost DESC
  LIMIT 1
),
inpatient_yearly AS (
  -- yearly average inpatient cost for the top provider
  SELECT
    CAST(yr AS INT64)                                      AS year,
    provider_id,
    AVG(average_medicare_payments * total_discharges)      AS avg_inpatient_cost
  FROM inpatient_raw
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
  GROUP BY year, provider_id
),
outpatient_raw AS (
  -- all outpatient rows 2011‑2015
  SELECT
    _TABLE_SUFFIX            AS yr,
    provider_id,
    average_total_payments,
    outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2015'
),
outpatient_yearly AS (
  -- yearly average outpatient cost for the same provider
  SELECT
    CAST(yr AS INT64)                                   AS year,
    provider_id,
    AVG(average_total_payments * outpatient_services)   AS avg_outpatient_cost
  FROM outpatient_raw
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
  GROUP BY year, provider_id
)
SELECT
  iy.provider_id,
  iy.year,
  iy.avg_inpatient_cost,
  oy.avg_outpatient_cost
FROM inpatient_yearly  iy
LEFT JOIN outpatient_yearly oy
  USING (provider_id, year)
ORDER BY year;