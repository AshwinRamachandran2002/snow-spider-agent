/*  Year-by-year average inpatient & outpatient cost for the provider
    with the highest TOTAL inpatient Medicare cost (2011-2015)         */

WITH
-- ---------------------------------------------------------------
-- 1)  All inpatient rows (years: 2011, 2013-2015)
-- ---------------------------------------------------------------
inpatient AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)                              AS year,
    provider_id,
    provider_name,
    average_medicare_payments * total_discharges              AS row_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_*`
  WHERE _TABLE_SUFFIX IN ('2011','2013','2014','2015')
),

-- ---------------------------------------------------------------
-- 2)  Provider with the largest TOTAL inpatient cost (2011-2015)
-- ---------------------------------------------------------------
top_provider AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name
  FROM inpatient
  GROUP BY provider_id
  ORDER BY SUM(row_cost) DESC
  LIMIT 1
),

-- ---------------------------------------------------------------
-- 3)  Year-by-year AVERAGE inpatient cost for that provider
-- ---------------------------------------------------------------
inpatient_yearly AS (
  SELECT
    year,
    AVG(row_cost) AS avg_inpatient_cost
  FROM inpatient
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  GROUP BY year
),

-- ---------------------------------------------------------------
-- 4)  All outpatient rows (years: 2011-2015)
-- ---------------------------------------------------------------
outpatient AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)                              AS year,
    provider_id,
    average_total_payments * outpatient_services              AS row_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_*`
  WHERE _TABLE_SUFFIX IN ('2011','2012','2013','2014','2015')
),

-- ---------------------------------------------------------------
-- 5)  Year-by-year AVERAGE outpatient cost for that provider
-- ---------------------------------------------------------------
outpatient_yearly AS (
  SELECT
    year,
    AVG(row_cost) AS avg_outpatient_cost
  FROM outpatient
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  GROUP BY year
),

-- ---------------------------------------------------------------
-- 6)  Helper table containing the five calendar years
-- ---------------------------------------------------------------
years AS (
  SELECT 2011 AS year UNION ALL
  SELECT 2012 UNION ALL
  SELECT 2013 UNION ALL
  SELECT 2014 UNION ALL
  SELECT 2015
)

-- ---------------------------------------------------------------
-- 7)  Combine yearly inpatient & outpatient averages
-- ---------------------------------------------------------------
SELECT
  y.year,
  i.avg_inpatient_cost,
  o.avg_outpatient_cost
FROM years                AS y
LEFT JOIN inpatient_yearly  i USING (year)
LEFT JOIN outpatient_yearly o USING (year)
ORDER BY y.year;