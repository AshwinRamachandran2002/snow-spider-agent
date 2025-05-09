-- 1) find the provider with the highest summed inpatient Medicare cost
WITH inpatient_all AS (
  -- gather the needed inpatient rows (2011‑2015)
  SELECT 2011 AS yr,
         provider_id,
         average_medicare_payments * total_discharges AS cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  UNION ALL
  SELECT 2012, provider_id,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
  UNION ALL
  SELECT 2013, provider_id,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  UNION ALL
  SELECT 2014, provider_id,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  UNION ALL
  SELECT 2015, provider_id,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
),
provider_totals AS (
  SELECT provider_id,
         SUM(cost) AS total_inpatient_cost_2011_2015
  FROM inpatient_all
  GROUP BY provider_id
),
top_provider AS (
  SELECT provider_id
  FROM provider_totals
  ORDER BY total_inpatient_cost_2011_2015 DESC
  LIMIT 1
),

-- 2) yearly average inpatient cost for that provider
inpatient_yearly AS (
  SELECT
    yr AS year,
    AVG(cost) AS inpatient_avg_cost
  FROM inpatient_all
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
  GROUP BY yr
),

-- 3) build outpatient set and yearly averages
outpatient_all AS (
  SELECT 2011 AS yr,
         provider_id,
         average_total_payments * outpatient_services AS cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  UNION ALL
  SELECT 2012, provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  UNION ALL
  SELECT 2013, provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  UNION ALL
  SELECT 2014, provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  UNION ALL
  SELECT 2015, provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
),
outpatient_yearly AS (
  SELECT
    yr AS year,
    AVG(cost) AS outpatient_avg_cost
  FROM outpatient_all
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
  GROUP BY yr
),

-- 4) combine inpatient & outpatient yearly numbers
years AS (
  SELECT 2011 AS year UNION ALL
  SELECT 2012 UNION ALL
  SELECT 2013 UNION ALL
  SELECT 2014 UNION ALL
  SELECT 2015
)
SELECT
  tp.provider_id,
  y.year,
  iy.inpatient_avg_cost,
  oy.outpatient_avg_cost
FROM years y
LEFT JOIN inpatient_yearly  iy USING(year)
LEFT JOIN outpatient_yearly oy USING(year)
CROSS JOIN top_provider tp
ORDER BY y.year;