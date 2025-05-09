WITH inpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    SUM(average_total_payments * total_discharges)   AS inpatient_total_payments,
    SUM(total_discharges)                            AS inpatient_total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
),
outpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name,
    SUM(average_total_payments * outpatient_services) AS outpatient_total_payments,
    SUM(outpatient_services)                          AS outpatient_total_services
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
),
combined AS (
  SELECT
    COALESCE(i.provider_id, o.provider_id)                          AS provider_id,
    COALESCE(i.provider_name, o.provider_name)                      AS provider_name,
    COALESCE(inpatient_total_payments, 0)   +
    COALESCE(outpatient_total_payments, 0)                          AS total_payments,
    COALESCE(inpatient_total_discharges, 0) +
    COALESCE(outpatient_total_services, 0)                          AS total_encounters
  FROM inpatient i
  FULL OUTER JOIN outpatient o
    ON i.provider_id = o.provider_id
)
SELECT
  provider_id,
  provider_name,
  total_payments / total_encounters AS combined_average_cost
FROM combined
WHERE total_encounters > 0
ORDER BY combined_average_cost DESC
LIMIT 1;