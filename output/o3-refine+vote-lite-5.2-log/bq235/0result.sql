WITH inpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name)                    AS provider_name,
    SUM(total_discharges * average_total_payments) AS total_payments,
    SUM(total_discharges)                          AS total_cases
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
),
outpatient AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name)                        AS provider_name,
    SUM(outpatient_services * average_total_payments) AS total_payments,
    SUM(outpatient_services)                          AS total_cases
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
),
combined AS (
  SELECT
    COALESCE(i.provider_id, o.provider_id)                    AS provider_id,
    COALESCE(i.provider_name, o.provider_name)                AS provider_name,
    COALESCE(i.total_payments, 0) + COALESCE(o.total_payments, 0) AS grand_total_payments,
    COALESCE(i.total_cases, 0)    + COALESCE(o.total_cases, 0)    AS grand_total_cases
  FROM inpatient  i
  FULL JOIN outpatient o
    ON i.provider_id = o.provider_id
),
ranked AS (
  SELECT
    provider_id,
    provider_name,
    grand_total_payments / NULLIF(grand_total_cases, 0) AS combined_average_cost
  FROM combined
)
SELECT
  provider_id,
  provider_name,
  combined_average_cost
FROM ranked
ORDER BY combined_average_cost DESC
LIMIT 1;