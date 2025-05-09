WITH
-- 1.  Inpatient yearly sums & averages for every provider
inpatient_yearly AS (
  SELECT 2011 AS year, provider_id,
         SUM(average_medicare_payments * total_discharges) AS year_sum_cost,
         AVG(average_medicare_payments * total_discharges) AS year_avg_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  GROUP BY provider_id
  UNION ALL
  SELECT 2012 AS year, provider_id,
         SUM(average_medicare_payments * total_discharges),
         AVG(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
  GROUP BY provider_id
  UNION ALL
  SELECT 2013 AS year, provider_id,
         SUM(average_medicare_payments * total_discharges),
         AVG(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  GROUP BY provider_id
  UNION ALL
  SELECT 2014 AS year, provider_id,
         SUM(average_medicare_payments * total_discharges),
         AVG(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
  UNION ALL
  SELECT 2015 AS year, provider_id,
         SUM(average_medicare_payments * total_discharges),
         AVG(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  GROUP BY provider_id
),

-- 2.  Provider with the highest total 2011‑2015 inpatient Medicare cost
top_inpatient_provider AS (
  SELECT provider_id
  FROM (
    SELECT provider_id,
           SUM(year_sum_cost) AS five_year_total_cost
    FROM inpatient_yearly
    GROUP BY provider_id
  )
  ORDER BY five_year_total_cost DESC
  LIMIT 1
),

-- 3.  Outpatient yearly averages for every provider
outpatient_yearly AS (
  SELECT 2011 AS year, provider_id,
         AVG(average_total_payments * outpatient_services) AS year_avg_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  GROUP BY provider_id
  UNION ALL
  SELECT 2012 AS year, provider_id,
         AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  GROUP BY provider_id
  UNION ALL
  SELECT 2013 AS year, provider_id,
         AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  GROUP BY provider_id
  UNION ALL
  SELECT 2014 AS year, provider_id,
         AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
  UNION ALL
  SELECT 2015 AS year, provider_id,
         AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
  GROUP BY provider_id
),

-- 4.  Yearly inpatient & outpatient averages for the top‑cost provider
provider_yearly_costs AS (
  SELECT iy.year,
         iy.year_avg_cost AS avg_inpatient_cost,
         oy.year_avg_cost AS avg_outpatient_cost
  FROM inpatient_yearly iy
  JOIN top_inpatient_provider p USING (provider_id)
  LEFT JOIN outpatient_yearly oy
         ON oy.provider_id = p.provider_id
        AND oy.year = iy.year
)

-- 5.  Final result
SELECT year,
       avg_inpatient_cost  AS average_inpatient_cost,
       avg_outpatient_cost AS average_outpatient_cost
FROM provider_yearly_costs
ORDER BY year;