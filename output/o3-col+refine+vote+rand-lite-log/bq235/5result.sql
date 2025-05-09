-- Provider with the highest combined (outpatient + inpatient) average Medicare payment in 2014
WITH outpatient AS (
  SELECT
    npi,
    nppes_provider_last_org_name  AS last_name,
    nppes_provider_first_name     AS first_name,
    SUM(average_medicare_payment_amt) AS outpatient_avg_cost
  FROM `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
  WHERE place_of_service = 'O'          -- Outpatient setting
  GROUP BY npi, last_name, first_name
),
inpatient AS (
  SELECT
    npi,
    nppes_provider_last_org_name  AS last_name,
    nppes_provider_first_name     AS first_name,
    SUM(average_medicare_payment_amt) AS inpatient_avg_cost
  FROM `bigquery-public-data.cms_medicare.physicians_and_other_supplier_2014`
  WHERE place_of_service = 'F'          -- Inpatient / facility setting
  GROUP BY npi, last_name, first_name
)
SELECT
  o.npi,
  o.last_name,
  o.first_name,
  o.outpatient_avg_cost,
  i.inpatient_avg_cost,
  (o.outpatient_avg_cost + i.inpatient_avg_cost) AS combined_avg_cost
FROM outpatient o
JOIN inpatient i
  USING (npi, last_name, first_name)
ORDER BY combined_avg_cost DESC
LIMIT 1;