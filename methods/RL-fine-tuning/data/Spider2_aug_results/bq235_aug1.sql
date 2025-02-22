-- Task: Can you find the healthcare provider with the highest weighted average inpatient payment in 2014?
SELECT 
  provider_id, 
  provider_name, 
  SUM(average_total_payments * total_discharges) / SUM(total_discharges) AS weighted_avg_inpatient_payment
FROM 
  `bigquery-public-data.cms_medicare.inpatient_charges_2014`
GROUP BY 
  provider_id, 
  provider_name
ORDER BY
  weighted_avg_inpatient_payment DESC
LIMIT 1;