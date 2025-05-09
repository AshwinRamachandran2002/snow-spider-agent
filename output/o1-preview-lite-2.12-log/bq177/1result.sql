WITH highest_cost_provider AS (
  SELECT provider_id
  FROM (
    SELECT provider_id,
           SUM(average_medicare_payments * total_discharges) AS total_inpatient_medicare_cost
    FROM (
      SELECT provider_id, average_medicare_payments, total_discharges
      FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
      UNION ALL
      SELECT provider_id, average_medicare_payments, total_discharges
      FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
      UNION ALL
      SELECT provider_id, average_medicare_payments, total_discharges
      FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
      UNION ALL
      SELECT provider_id, average_medicare_payments, total_discharges
      FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
      UNION ALL
      SELECT provider_id, average_medicare_payments, total_discharges
      FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
    )
    GROUP BY provider_id
    ORDER BY total_inpatient_medicare_cost DESC
    LIMIT 1
  )
),
combined_data AS (
  SELECT
    '2011' AS Year,
    'inpatient' AS type,
    average_medicare_payments * total_discharges AS cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)

  UNION ALL

  SELECT
    '2011' AS Year,
    'outpatient' AS type,
    average_total_payments * outpatient_services AS cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)

  UNION ALL

  SELECT
    '2012' AS Year,
    'inpatient' AS type,
    average_medicare_payments * total_discharges AS cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)

  UNION ALL

  SELECT
    '2012' AS Year,
    'outpatient' AS type,
    average_total_payments * outpatient_services AS cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)

  UNION ALL

  SELECT
    '2013' AS Year,
    'inpatient' AS type,
    average_medicare_payments * total_discharges AS cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)

  UNION ALL

  SELECT
    '2013' AS Year,
    'outpatient' AS type,
    average_total_payments * outpatient_services AS cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)

  UNION ALL

  SELECT
    '2014' AS Year,
    'inpatient' AS type,
    average_medicare_payments * total_discharges AS cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)

  UNION ALL

  SELECT
    '2014' AS Year,
    'outpatient' AS type,
    average_total_payments * outpatient_services AS cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)

  UNION ALL

  SELECT
    '2015' AS Year,
    'inpatient' AS type,
    average_medicare_payments * total_discharges AS cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)

  UNION ALL

  SELECT
    '2015' AS Year,
    'outpatient' AS type,
    average_total_payments * outpatient_services AS cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
  WHERE provider_id = (SELECT provider_id FROM highest_cost_provider)
)
SELECT
  Year,
  ROUND(AVG(CASE WHEN type = 'inpatient' THEN cost END), 4) AS Average_inpatient_cost,
  ROUND(AVG(CASE WHEN type = 'outpatient' THEN cost END), 4) AS Average_outpatient_cost
FROM combined_data
GROUP BY Year
ORDER BY Year;