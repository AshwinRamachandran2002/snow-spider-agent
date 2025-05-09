-- Yearly average inpatient and outpatient costs for the single provider
-- with the largest total inpatient Medicare spend (2011-2015).

WITH all_inpatient AS (        -- every inpatient row we have (2011, 2013-15)
  SELECT provider_id, provider_name,
         total_discharges * average_medicare_payments AS row_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  UNION ALL
  SELECT provider_id, provider_name,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  UNION ALL
  SELECT provider_id, provider_name,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  UNION ALL
  SELECT provider_id, provider_name,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
),
-- Provider whose summed inpatient cost is the greatest.
top_provider AS (
  SELECT provider_id, ANY_VALUE(provider_name) AS provider_name
  FROM all_inpatient
  GROUP BY provider_id
  ORDER BY SUM(row_cost) DESC
  LIMIT 1
),

-- Year-by-year average inpatient cost for that provider
yearly_inpatient AS (
  SELECT 2011 AS year,
         AVG(total_discharges * average_medicare_payments) AS avg_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT 2013,
         AVG(total_discharges * average_medicare_payments)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT 2014,
         AVG(total_discharges * average_medicare_payments)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT 2015,
         AVG(total_discharges * average_medicare_payments)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
),

-- Year-by-year average outpatient cost for the same provider
yearly_outpatient AS (
  SELECT 2011 AS year,
         AVG(outpatient_services * average_total_payments) AS avg_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT 2012,
         AVG(outpatient_services * average_total_payments)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT 2013,
         AVG(outpatient_services * average_total_payments)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT 2014,
         AVG(outpatient_services * average_total_payments)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT 2015,
         AVG(outpatient_services * average_total_payments)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
)

-- Final answer: yearly averages where both inpatient & outpatient data exist.
SELECT
  tp.provider_name,
  yi.year,
  yi.avg_inpatient_cost,
  yo.avg_outpatient_cost
FROM yearly_inpatient yi
JOIN yearly_outpatient yo USING (year)
CROSS JOIN top_provider tp
ORDER BY yi.year;