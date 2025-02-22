-- Task: Find the healthcare provider in 2014 with the highest combined weighted average total payments for inpatient and outpatient services. The weighted average total payments for inpatient services are calculated by summing the products of average total payments and total discharges for all procedures, divided by the total discharges. Similarly, for outpatient services, it is calculated by summing the products of average total payments and outpatient services, divided by the total outpatient services.
WITH weighted_avg_inpatient AS (
  SELECT 
    provider_id, 
    provider_name, 
    SUM(average_total_payments * total_discharges) / SUM(total_discharges) AS weighted_avg_inpatient_payment
  FROM 
    `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY 
    provider_id, 
    provider_name
),
weighted_avg_outpatient AS (
  SELECT 
    provider_id, 
    provider_name, 
    SUM(average_total_payments * outpatient_services) / SUM(outpatient_services) AS weighted_avg_outpatient_payment
  FROM 
    `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  WHERE outpatient_services > 0
  GROUP BY 
    provider_id, 
    provider_name
)
SELECT
  i.provider_id AS Provider_ID,
  i.provider_name AS Provider_Name,
  ROUND(i.weighted_avg_inpatient_payment + o.weighted_avg_outpatient_payment, 4) AS Combined_Total_Payments
FROM 
  weighted_avg_inpatient i
JOIN 
  weighted_avg_outpatient o ON i.provider_id = o.provider_id
ORDER BY 
  Combined_Total_Payments DESC
LIMIT 1;