/* 1) Identify the provider with the largest TOTAL inpatient cost (2011-2015)
   2) For that provider, compute the YEARLY average inpatient and outpatient costs
      (average of   average_medicare_payments*total_discharges   and
       average_total_payments*outpatient_services  respectively)
   3) Return one row per calendar year 2011-2015                      */

WITH inpatient AS (        -- stack all available inpatient tables
  SELECT 2011 AS year,
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
/* provider with the single highest TOTAL inpatient cost across 2011-2015 */
top_provider AS (
  SELECT provider_id,
         ANY_VALUE(provider_name) AS provider_name,
         SUM(row_cost)            AS total_inpatient_cost
  FROM inpatient
  GROUP BY provider_id
  ORDER BY total_inpatient_cost DESC
  LIMIT 1
),
/* yearly AVG( inpatient row-level cost ) for that provider */
yearly_inpatient AS (
  SELECT i.year,
         AVG(i.row_cost) AS avg_inpatient_cost
  FROM inpatient  i
  JOIN top_provider tp USING (provider_id)
  GROUP BY i.year
),
/* stack outpatient tables 2011-2015 */
outpatient AS (
  SELECT 2011 AS year,
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
/* yearly AVG( outpatient row-level cost ) for that provider */
yearly_outpatient AS (
  SELECT o.year,
         AVG(o.row_cost) AS avg_outpatient_cost
  FROM outpatient o
  JOIN top_provider tp USING (provider_id)
  GROUP BY o.year
),
-- ensure one output row per calendar year 2011-2015
calendar_years AS (
  SELECT 2011 AS year UNION ALL
  SELECT 2012 UNION ALL
  SELECT 2013 UNION ALL
  SELECT 2014 UNION ALL
  SELECT 2015
)
SELECT
  cy.year,
  yi.avg_inpatient_cost,
  yo.avg_outpatient_cost
FROM calendar_years      AS cy
LEFT JOIN yearly_inpatient  yi USING (year)
LEFT JOIN yearly_outpatient yo USING (year)
ORDER BY cy.year;