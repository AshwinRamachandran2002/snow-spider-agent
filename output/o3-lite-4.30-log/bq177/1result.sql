WITH inpatient_union AS (
  SELECT provider_id,
         2011 AS calendar_year,
         total_discharges * average_medicare_payments AS cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  UNION ALL
  SELECT provider_id,
         2012,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
  UNION ALL
  SELECT provider_id,
         2013,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  UNION ALL
  SELECT provider_id,
         2014,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  UNION ALL
  SELECT provider_id,
         2015,
         total_discharges * average_medicare_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
),
-- provider with greatest total inpatient cost (2011‑2015)
top_provider AS (
  SELECT provider_id
  FROM inpatient_union
  GROUP BY provider_id
  ORDER BY SUM(cost) DESC
  LIMIT 1
),
yearly_inpatient AS (
  SELECT provider_id,
         calendar_year,
         ROUND(AVG(cost),4) AS average_inpatient_cost
  FROM inpatient_union
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  GROUP BY provider_id, calendar_year
),
outpatient_union AS (
  SELECT provider_id,
         2011 AS calendar_year,
         outpatient_services * average_total_payments AS cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  UNION ALL
  SELECT provider_id,
         2012,
         outpatient_services * average_total_payments
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  UNION ALL
  SELECT provider_id,
         2013,
         outpatient_services * average_total_payments
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  UNION ALL
  SELECT provider_id,
         2014,
         outpatient_services * average_total_payments
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  UNION ALL
  SELECT provider_id,
         2015,
         outpatient_services * average_total_payments
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
),
yearly_outpatient AS (
  SELECT provider_id,
         calendar_year,
         ROUND(AVG(cost),4) AS average_outpatient_cost
  FROM outpatient_union
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  GROUP BY provider_id, calendar_year
)
SELECT CAST(i.calendar_year AS STRING) AS calendar_year,
       i.average_inpatient_cost,
       o.average_outpatient_cost
FROM yearly_inpatient AS i
JOIN yearly_outpatient AS o
  ON i.provider_id    = o.provider_id
 AND i.calendar_year = o.calendar_year
ORDER BY calendar_year;