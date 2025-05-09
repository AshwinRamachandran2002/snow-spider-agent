WITH top_provider AS (
  SELECT provider_id
  FROM (
    SELECT provider_id, SUM(average_medicare_payments * total_discharges) AS total_inpatient_cost
    FROM (
      SELECT provider_id, average_medicare_payments, total_discharges FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
      UNION ALL
      SELECT provider_id, average_medicare_payments, total_discharges FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
      UNION ALL
      SELECT provider_id, average_medicare_payments, total_discharges FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
      UNION ALL
      SELECT provider_id, average_medicare_payments, total_discharges FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
      UNION ALL
      SELECT provider_id, average_medicare_payments, total_discharges FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
    )
    GROUP BY provider_id
    ORDER BY total_inpatient_cost DESC
    LIMIT 1
  )
),
inpatient AS (
  SELECT '2011' AS Year, ROUND(AVG(average_medicare_payments * total_discharges), 4) AS Average_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
  UNION ALL
  SELECT '2012', ROUND(AVG(average_medicare_payments * total_discharges), 4)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
  UNION ALL
  SELECT '2013', ROUND(AVG(average_medicare_payments * total_discharges), 4)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
  UNION ALL
  SELECT '2014', ROUND(AVG(average_medicare_payments * total_discharges), 4)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
  UNION ALL
  SELECT '2015', ROUND(AVG(average_medicare_payments * total_discharges), 4)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
),
outpatient AS (
  SELECT '2011' AS Year, ROUND(AVG(average_total_payments * outpatient_services), 4) AS Average_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
  UNION ALL
  SELECT '2012', ROUND(AVG(average_total_payments * outpatient_services), 4)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
  UNION ALL
  SELECT '2013', ROUND(AVG(average_total_payments * outpatient_services), 4)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
  UNION ALL
  SELECT '2014', ROUND(AVG(average_total_payments * outpatient_services), 4)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
  UNION ALL
  SELECT '2015', ROUND(AVG(average_total_payments * outpatient_services), 4)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015` t
  JOIN top_provider tp ON t.provider_id = tp.provider_id
)
SELECT inpatient.Year, inpatient.Average_inpatient_cost, outpatient.Average_outpatient_cost
FROM inpatient
LEFT JOIN outpatient USING (Year)
ORDER BY CAST(inpatient.Year AS INT64);