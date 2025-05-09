WITH provider_with_highest_cost AS (
  SELECT
    provider_id,
    provider_name,
    SUM(total_discharges * average_total_payments) AS total_inpatient_service_cost
  FROM (
    SELECT provider_id, provider_name, total_discharges, average_total_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
    UNION ALL
    SELECT provider_id, provider_name, total_discharges, average_total_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
    UNION ALL
    SELECT provider_id, provider_name, total_discharges, average_total_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
    UNION ALL
    SELECT provider_id, provider_name, total_discharges, average_total_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
    UNION ALL
    SELECT provider_id, provider_name, total_discharges, average_total_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  )
  GROUP BY provider_id, provider_name
  ORDER BY total_inpatient_service_cost DESC
  LIMIT 1
),
provider_id_to_use AS (
  SELECT provider_id FROM provider_with_highest_cost
)
SELECT
  Year,
  ROUND(SUM(inpatient_revenue) / SUM(inpatient_cases), 4) AS Average_Inpatient_Revenue_per_Case,
  ROUND(SUM(outpatient_revenue) / SUM(outpatient_cases), 4) AS Average_Outpatient_Revenue_per_Case
FROM (
  SELECT
    '2011' AS Year,
    SUM(total_discharges * average_total_payments) AS inpatient_revenue,
    SUM(total_discharges) AS inpatient_cases,
    0 AS outpatient_revenue,
    0 AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
  UNION ALL
  SELECT
    '2011' AS Year,
    0 AS inpatient_revenue,
    0 AS inpatient_cases,
    SUM(outpatient_services * average_total_payments) AS outpatient_revenue,
    SUM(outpatient_services) AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
  UNION ALL
  SELECT
    '2012' AS Year,
    SUM(total_discharges * average_total_payments) AS inpatient_revenue,
    SUM(total_discharges) AS inpatient_cases,
    0 AS outpatient_revenue,
    0 AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
  UNION ALL
  SELECT
    '2012' AS Year,
    0 AS inpatient_revenue,
    0 AS inpatient_cases,
    SUM(outpatient_services * average_total_payments) AS outpatient_revenue,
    SUM(outpatient_services) AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
  UNION ALL
  SELECT
    '2013' AS Year,
    SUM(total_discharges * average_total_payments) AS inpatient_revenue,
    SUM(total_discharges) AS inpatient_cases,
    0 AS outpatient_revenue,
    0 AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
  UNION ALL
  SELECT
    '2013' AS Year,
    0 AS inpatient_revenue,
    0 AS inpatient_cases,
    SUM(outpatient_services * average_total_payments) AS outpatient_revenue,
    SUM(outpatient_services) AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
  UNION ALL
  SELECT
    '2014' AS Year,
    SUM(total_discharges * average_total_payments) AS inpatient_revenue,
    SUM(total_discharges) AS inpatient_cases,
    0 AS outpatient_revenue,
    0 AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
  UNION ALL
  SELECT
    '2014' AS Year,
    0 AS inpatient_revenue,
    0 AS inpatient_cases,
    SUM(outpatient_services * average_total_payments) AS outpatient_revenue,
    SUM(outpatient_services) AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
  UNION ALL
  SELECT
    '2015' AS Year,
    SUM(total_discharges * average_total_payments) AS inpatient_revenue,
    SUM(total_discharges) AS inpatient_cases,
    0 AS outpatient_revenue,
    0 AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
  UNION ALL
  SELECT
    '2015' AS Year,
    0 AS inpatient_revenue,
    0 AS inpatient_cases,
    SUM(outpatient_services * average_total_payments) AS outpatient_revenue,
    SUM(outpatient_services) AS outpatient_cases
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
  WHERE provider_id IN (SELECT provider_id FROM provider_id_to_use)
) AS combined_data
GROUP BY Year
ORDER BY Year;