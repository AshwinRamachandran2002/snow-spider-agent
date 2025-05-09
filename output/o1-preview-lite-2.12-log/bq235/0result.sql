SELECT
  inpatient.provider_id AS Provider_ID,
  inpatient.provider_name AS Provider_Name,
  ROUND(
    (inpatient.total_inpatient_payments + outpatient.total_outpatient_payments) / (inpatient.total_inpatient_discharges + outpatient.total_outpatient_services),
    4
  ) AS Combined_Total_Payments
FROM
  (
    SELECT
      provider_id,
      provider_name,
      SUM(average_total_payments * total_discharges) AS total_inpatient_payments,
      SUM(total_discharges) AS total_inpatient_discharges
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
    GROUP BY provider_id, provider_name
  ) AS inpatient
JOIN
  (
    SELECT
      provider_id,
      provider_name,
      SUM(average_total_payments * outpatient_services) AS total_outpatient_payments,
      SUM(outpatient_services) AS total_outpatient_services
    FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
    GROUP BY provider_id, provider_name
  ) AS outpatient
ON inpatient.provider_id = outpatient.provider_id
WHERE (inpatient.total_inpatient_discharges + outpatient.total_outpatient_services) > 0
ORDER BY Combined_Total_Payments DESC
LIMIT 1;