/*  Year-by-year average inpatient & outpatient cost for the single provider
    that generated the largest total inpatient Medicare cost during 2011-2015  */

WITH year_cost AS (                    -- inpatient cost for every provider, each year
  SELECT provider_id,
         SUM(average_medicare_payments * total_discharges) AS cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  GROUP BY provider_id

  UNION ALL
  SELECT provider_id,
         SUM(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  GROUP BY provider_id

  UNION ALL
  SELECT provider_id,
         SUM(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id

  UNION ALL
  SELECT provider_id,
         SUM(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  GROUP BY provider_id
),

top_provider AS (                      -- provider with the highest 2011-2015 inpatient cost
  SELECT provider_id
  FROM year_cost
  GROUP BY provider_id
  ORDER BY SUM(cost) DESC
  LIMIT 1
),

/* --------  YEARLY AVERAGE INPATIENT COSTS (avg of cost per record) -------- */
inpatient_yearly AS (
  -- 2011
  SELECT 2011 AS year,
         ROUND(AVG(average_medicare_payments * total_discharges),4) AS avg_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  WHERE provider_id IN (SELECT provider_id FROM top_provider)

  UNION ALL
  -- 2013
  SELECT 2013,
         ROUND(AVG(average_medicare_payments * total_discharges),4)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  WHERE provider_id IN (SELECT provider_id FROM top_provider)

  UNION ALL
  -- 2014
  SELECT 2014,
         ROUND(AVG(average_medicare_payments * total_discharges),4)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE provider_id IN (SELECT provider_id FROM top_provider)

  UNION ALL
  -- 2015
  SELECT 2015,
         ROUND(AVG(average_medicare_payments * total_discharges),4)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
),

/* --------  YEARLY AVERAGE OUTPATIENT COSTS (avg of cost per record) -------- */
outpatient_yearly AS (
  SELECT 2011 AS year,
         ROUND(AVG(average_total_payments * outpatient_services),4) AS avg_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  WHERE provider_id IN (SELECT provider_id FROM top_provider)

  UNION ALL
  SELECT 2012,
         ROUND(AVG(average_total_payments * outpatient_services),4)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  WHERE provider_id IN (SELECT provider_id FROM top_provider)

  UNION ALL
  SELECT 2013,
         ROUND(AVG(average_total_payments * outpatient_services),4)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  WHERE provider_id IN (SELECT provider_id FROM top_provider)

  UNION ALL
  SELECT 2014,
         ROUND(AVG(average_total_payments * outpatient_services),4)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  WHERE provider_id IN (SELECT provider_id FROM top_provider)

  UNION ALL
  SELECT 2015,
         ROUND(AVG(average_total_payments * outpatient_services),4)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
),

/* --------  FINAL YEAR LIST (ensures 2012 is present even though inpatient data is absent) -------- */
years AS (
  SELECT 2011 AS year UNION ALL
  SELECT 2012 UNION ALL
  SELECT 2013 UNION ALL
  SELECT 2014 UNION ALL
  SELECT 2015
)

SELECT
  y.year,
  i.avg_inpatient_cost,
  o.avg_outpatient_cost
FROM years AS y
LEFT JOIN inpatient_yearly  AS i USING (year)
LEFT JOIN outpatient_yearly AS o USING (year)
ORDER BY y.year;