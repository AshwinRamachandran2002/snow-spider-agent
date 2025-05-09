WITH inpatient AS (
  -- Yearly inpatient stats per provider
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, -4) AS INT64) AS year,
    provider_id,
    ANY_VALUE(provider_name)                                                    AS provider_name,
    SUM(average_medicare_payments * total_discharges)                           AS total_inpatient_cost,
    AVG(average_medicare_payments * total_discharges)                           AS avg_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2015'
  GROUP BY year, provider_id
),
provider_totals AS (
  -- Cumulative (2011‑2015) inpatient cost per provider
  SELECT
    provider_id,
    SUM(total_inpatient_cost) AS total_cost_2011_2015
  FROM inpatient
  GROUP BY provider_id
),
top_provider AS (
  -- Provider with the highest cumulative inpatient cost
  SELECT provider_id
  FROM provider_totals
  ORDER BY total_cost_2011_2015 DESC
  LIMIT 1
),
outpatient AS (
  -- Yearly outpatient stats per provider
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, -4) AS INT64) AS year,
    provider_id,
    AVG(average_total_payments * outpatient_services) AS avg_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2015'
  GROUP BY year, provider_id
),
years AS (
  SELECT 2011 AS year UNION ALL
  SELECT 2012 UNION ALL
  SELECT 2013 UNION ALL
  SELECT 2014 UNION ALL
  SELECT 2015
)

-- Final result
SELECT
  y.year,
  tp.provider_id,
  ANY_VALUE(i.provider_name)                     AS provider_name,
  MAX(i.avg_inpatient_cost)                      AS yearly_avg_inpatient_cost,
  MAX(o.avg_outpatient_cost)                     AS yearly_avg_outpatient_cost
FROM top_provider tp
CROSS JOIN years y
LEFT JOIN inpatient  i ON i.provider_id = tp.provider_id AND i.year = y.year
LEFT JOIN outpatient o ON o.provider_id = tp.provider_id AND o.year = y.year
GROUP BY y.year, tp.provider_id
ORDER BY y.year;