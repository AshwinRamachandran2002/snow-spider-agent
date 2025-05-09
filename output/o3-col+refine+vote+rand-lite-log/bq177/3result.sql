/*  Year-by-year average inpatient vs. outpatient cost for the single
    provider whose 2011-2015 TOTAL inpatient cost is the very highest   */

WITH inpatient_all AS (
  -- Collect every inpatient row (tables exist for 2011, 2013-2015)
  SELECT provider_id,
         provider_name,
         2011 AS yr,
         total_discharges * average_medicare_payments AS row_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  UNION ALL
  SELECT provider_id, provider_name, 2013,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  UNION ALL
  SELECT provider_id, provider_name, 2014,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  UNION ALL
  SELECT provider_id, provider_name, 2015,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
),
-- Identify the single provider with the greatest 2011-2015 inpatient cost
top_provider AS (
  SELECT provider_id,
         ANY_VALUE(provider_name) AS provider_name,
         SUM(row_cost)            AS total_inpatient_cost
  FROM inpatient_all
  GROUP BY provider_id
  ORDER BY total_inpatient_cost DESC
  LIMIT 1
),
-- Yearly AVERAGE inpatient cost for that provider
inpatient_yearly AS (
  SELECT ia.yr,
         AVG(ia.row_cost) AS avg_inpatient_cost
  FROM   inpatient_all AS ia
  JOIN   top_provider  AS tp
  ON     ia.provider_id = tp.provider_id
  GROUP  BY ia.yr
),
/* ------------------------------------------------------------------ */
outpatient_all AS (
  -- Collect every outpatient row (tables exist for 2011-2015)
  SELECT provider_id,
         provider_name,
         2011 AS yr,
         outpatient_services * average_total_payments AS row_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  UNION ALL
  SELECT provider_id, provider_name, 2012,
         outpatient_services * average_total_payments
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  UNION ALL
  SELECT provider_id, provider_name, 2013,
         outpatient_services * average_total_payments
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  UNION ALL
  SELECT provider_id, provider_name, 2014,
         outpatient_services * average_total_payments
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  UNION ALL
  SELECT provider_id, provider_name, 2015,
         outpatient_services * average_total_payments
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
),
-- Yearly AVERAGE outpatient cost for that provider
outpatient_yearly AS (
  SELECT oa.yr,
         AVG(oa.row_cost) AS avg_outpatient_cost
  FROM   outpatient_all AS oa
  JOIN   top_provider   AS tp
  ON     oa.provider_id = tp.provider_id
  GROUP  BY oa.yr
),
-- Generate the five calendar years 2011-2015
years AS (
  SELECT 2011 AS yr UNION ALL
  SELECT 2012 UNION ALL
  SELECT 2013 UNION ALL
  SELECT 2014 UNION ALL
  SELECT 2015
)
-- Final result: one row per year with both averages
SELECT
  y.yr                                   AS year,
  iy.avg_inpatient_cost,
  oy.avg_outpatient_cost
FROM        years            AS y
LEFT JOIN   inpatient_yearly AS iy  USING (yr)
LEFT JOIN   outpatient_yearly AS oy USING (yr)
ORDER BY y.yr;