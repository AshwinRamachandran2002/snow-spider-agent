/*  Year-by-year average inpatient and outpatient costs for the single provider
    that generated the greatest TOTAL inpatient Medicare cost during 2011-2015  */

WITH inpatient AS (     -- every inpatient row 2011-2015 (2012 data not published)
  SELECT 2011 AS yr,
         provider_id,
         provider_name,
         average_medicare_payments * total_discharges AS row_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  UNION ALL
  SELECT 2013,
         provider_id,
         provider_name,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  UNION ALL
  SELECT 2014,
         provider_id,
         provider_name,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  UNION ALL
  SELECT 2015,
         provider_id,
         provider_name,
         average_medicare_payments * total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
),
/* Identify the provider with the highest total inpatient cost (sum of row_cost) */
top_provider AS (
  SELECT provider_id
  FROM inpatient
  GROUP BY provider_id
  ORDER BY SUM(row_cost) DESC
  LIMIT 1
),
/* Yearly AVG of row-level inpatient cost for the top provider */
yearly_inpatient AS (
  SELECT
    yr,
    AVG(row_cost) AS avg_inpatient_cost
  FROM inpatient
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  GROUP BY yr
),
/* All outpatient rows 2011-2015 */
outpatient AS (
  SELECT 2011 AS yr,
         provider_id,
         average_total_payments * outpatient_services AS row_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  UNION ALL
  SELECT 2012,
         provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  UNION ALL
  SELECT 2013,
         provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  UNION ALL
  SELECT 2014,
         provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  UNION ALL
  SELECT 2015,
         provider_id,
         average_total_payments * outpatient_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
),
/* Yearly AVG of row-level outpatient cost for the top provider */
yearly_outpatient AS (
  SELECT
    yr,
    AVG(row_cost) AS avg_outpatient_cost
  FROM outpatient
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  GROUP BY yr
)
/* Combine inpatient and outpatient averages, one row per calendar year */
SELECT
  COALESCE(i.yr, o.yr)        AS calendar_year,
  i.avg_inpatient_cost,
  o.avg_outpatient_cost
FROM yearly_inpatient AS i
FULL OUTER JOIN yearly_outpatient AS o
ON i.yr = o.yr
ORDER BY calendar_year;