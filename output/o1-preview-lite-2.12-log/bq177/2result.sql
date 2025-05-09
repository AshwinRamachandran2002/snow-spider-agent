WITH total_inpatient_costs AS (
  SELECT provider_id, SUM(total_inpatient_payments) AS total_inpatient_payments_overall
  FROM (
    SELECT provider_id, SUM(average_medicare_payments * total_discharges) AS total_inpatient_payments
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
    GROUP BY provider_id
    UNION ALL
    SELECT provider_id, SUM(average_medicare_payments * total_discharges)
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
    GROUP BY provider_id
    UNION ALL
    SELECT provider_id, SUM(average_medicare_payments * total_discharges)
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
    GROUP BY provider_id
    UNION ALL
    SELECT provider_id, SUM(average_medicare_payments * total_discharges)
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
    GROUP BY provider_id
    UNION ALL
    SELECT provider_id, SUM(average_medicare_payments * total_discharges)
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
    GROUP BY provider_id
  )
  GROUP BY provider_id
),
top_provider AS (
  SELECT provider_id
  FROM total_inpatient_costs
  ORDER BY total_inpatient_payments_overall DESC
  LIMIT 1
),
yearly_inpatient_cost AS (
  SELECT
    2011 AS Year,
    AVG(average_medicare_payments * total_discharges) AS Average_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2011`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT
    2012 AS Year,
    AVG(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2012`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT
    2013 AS Year,
    AVG(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2013`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT
    2014 AS Year,
    AVG(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT
    2015 AS Year,
    AVG(average_medicare_payments * total_discharges)
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2015`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
),
yearly_outpatient_cost AS (
  SELECT
    2011 AS Year,
    AVG(average_total_payments * outpatient_services) AS Average_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2011`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT
    2012 AS Year,
    AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2012`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT
    2013 AS Year,
    AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2013`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT
    2014 AS Year,
    AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  UNION ALL
  SELECT
    2015 AS Year,
    AVG(average_total_payments * outpatient_services)
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2015`
  WHERE provider_id = (SELECT provider_id FROM top_provider)
)
SELECT
  yic.Year,
  ROUND(yic.Average_inpatient_cost, 4) AS Average_inpatient_cost,
  ROUND(yoc.Average_outpatient_cost, 4) AS Average_outpatient_cost
FROM
  yearly_inpatient_cost yic
LEFT JOIN
  yearly_outpatient_cost yoc
ON
  yic.Year = yoc.Year
ORDER BY
  yic.Year;