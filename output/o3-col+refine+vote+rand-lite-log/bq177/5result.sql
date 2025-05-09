/*  Year-by-year average inpatient & outpatient cost for the single provider
    that had the highest TOTAL inpatient Medicare cost across 2011-2015       */

WITH provider_total AS (      -- find the top-cost provider (ID & name)
  SELECT
    provider_id,
    provider_name,
    SUM(total_discharges * average_medicare_payments) AS total_inpatient_cost
  FROM (
    SELECT provider_id, provider_name, total_discharges, average_medicare_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
    UNION ALL
    SELECT provider_id, provider_name, total_discharges, average_medicare_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
    UNION ALL
    SELECT provider_id, provider_name, total_discharges, average_medicare_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
    UNION ALL
    SELECT provider_id, provider_name, total_discharges, average_medicare_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  )
  GROUP BY provider_id, provider_name
  ORDER BY total_inpatient_cost DESC
  LIMIT 1
),

/* yearly average INPATIENT cost (= AVG(payments × discharges)) */
inpatient_yearly AS (
  SELECT 2011 AS year, provider_id,
         AVG(total_discharges * average_medicare_payments) AS avg_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  GROUP BY provider_id
  UNION ALL
  SELECT 2013, provider_id,
         AVG(total_discharges * average_medicare_payments)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  GROUP BY provider_id
  UNION ALL
  SELECT 2014, provider_id,
         AVG(total_discharges * average_medicare_payments)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
  UNION ALL
  SELECT 2015, provider_id,
         AVG(total_discharges * average_medicare_payments)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  GROUP BY provider_id
),

/* yearly average OUTPATIENT cost (= AVG(total_payments × services)) */
outpatient_yearly AS (
  SELECT 2011 AS year, provider_id,
         AVG(outpatient_services * average_total_payments) AS avg_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  GROUP BY provider_id
  UNION ALL
  SELECT 2012, provider_id,
         AVG(outpatient_services * average_total_payments)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  GROUP BY provider_id
  UNION ALL
  SELECT 2013, provider_id,
         AVG(outpatient_services * average_total_payments)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  GROUP BY provider_id
  UNION ALL
  SELECT 2014, provider_id,
         AVG(outpatient_services * average_total_payments)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
  UNION ALL
  SELECT 2015, provider_id,
         AVG(outpatient_services * average_total_payments)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
  GROUP BY provider_id
),

years AS (                     -- ensure every calendar year appears
  SELECT 2011 AS year UNION ALL
  SELECT 2012 UNION ALL
  SELECT 2013 UNION ALL
  SELECT 2014 UNION ALL
  SELECT 2015
)

SELECT
  pt.provider_id,
  pt.provider_name,
  y.year,
  i.avg_inpatient_cost,
  o.avg_outpatient_cost
FROM years y
CROSS JOIN provider_total pt
LEFT JOIN inpatient_yearly  i
  ON i.provider_id = pt.provider_id AND i.year = y.year
LEFT JOIN outpatient_yearly o
  ON o.provider_id = pt.provider_id AND o.year = y.year
ORDER BY y.year;