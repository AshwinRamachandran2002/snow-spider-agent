WITH inpatient_yearly AS (
  -- 2011
  SELECT '2011' AS calendar_year,
         provider_id,
         AVG(average_medicare_payments * total_discharges) AS avg_inpatient_cost,
         SUM(average_medicare_payments * total_discharges) AS sum_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  GROUP BY provider_id
  UNION ALL
  -- 2012
  SELECT '2012',
         provider_id,
         AVG(average_medicare_payments * total_discharges),
         SUM(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
  GROUP BY provider_id
  UNION ALL
  -- 2013
  SELECT '2013',
         provider_id,
         AVG(average_medicare_payments * total_discharges),
         SUM(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  GROUP BY provider_id
  UNION ALL
  -- 2014
  SELECT '2014',
         provider_id,
         AVG(average_medicare_payments * total_discharges),
         SUM(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
  UNION ALL
  -- 2015
  SELECT '2015',
         provider_id,
         AVG(average_medicare_payments * total_discharges),
         SUM(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  GROUP BY provider_id
),
-- provider with the largest TOTAL inpatient cost (sum of payments × discharges)
top_provider AS (
  SELECT provider_id
  FROM inpatient_yearly
  GROUP BY provider_id
  ORDER BY SUM(sum_inpatient_cost) DESC
  LIMIT 1
),
outpatient_yearly AS (
  -- 2011
  SELECT '2011' AS calendar_year,
         provider_id,
         AVG(average_total_payments * outpatient_services) AS avg_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  GROUP BY provider_id
  UNION ALL
  -- 2012
  SELECT '2012',
         provider_id,
         AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  GROUP BY provider_id
  UNION ALL
  -- 2013
  SELECT '2013',
         provider_id,
         AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  GROUP BY provider_id
  UNION ALL
  -- 2014
  SELECT '2014',
         provider_id,
         AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
  UNION ALL
  -- 2015
  SELECT '2015',
         provider_id,
         AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
  GROUP BY provider_id
)
SELECT
  iy.calendar_year,
  ROUND(iy.avg_inpatient_cost, 4)  AS average_inpatient_cost,
  ROUND(oy.avg_outpatient_cost, 4) AS average_outpatient_cost
FROM inpatient_yearly AS iy
JOIN top_provider AS tp
  ON iy.provider_id = tp.provider_id
LEFT JOIN outpatient_yearly AS oy
  ON oy.provider_id   = tp.provider_id
 AND oy.calendar_year = iy.calendar_year
ORDER BY iy.calendar_year;