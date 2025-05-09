WITH inpatient_all AS (
  SELECT 2011 AS calendar_year,
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
top_provider AS (
  SELECT provider_id
  FROM inpatient_all
  GROUP BY provider_id
  ORDER BY SUM(cost) DESC
  LIMIT 1
),
yearly_inpatient_avg AS (
  SELECT
    calendar_year,
    ROUND(AVG(cost), 4) AS average_inpatient_cost
  FROM inpatient_all
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
  GROUP BY calendar_year
),
outpatient_all AS (
  SELECT 2011 AS calendar_year,
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
yearly_outpatient_avg AS (
  SELECT
    calendar_year,
    ROUND(AVG(cost), 4) AS average_outpatient_cost
  FROM outpatient_all
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
  GROUP BY calendar_year
)
SELECT
  CAST(i.calendar_year AS STRING) AS calendar_year,
  i.average_inpatient_cost,
  o.average_outpatient_cost
FROM yearly_inpatient_avg i
JOIN yearly_outpatient_avg o USING (calendar_year)
ORDER BY calendar_year;