WITH outpatient AS (
  SELECT
    provider_id,
    AVG(average_estimated_submitted_charges) AS avg_outpatient
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
  GROUP BY provider_id
),
inpatient AS (
  SELECT
    provider_id,
    AVG(average_covered_charges) AS avg_inpatient
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY provider_id
),
provider_names AS (
  SELECT
    provider_id,
    ANY_VALUE(provider_name) AS provider_name
  FROM (
    SELECT provider_id, provider_name
    FROM `bigquery-public-data.cms_medicare.outpatient_charges_2014`
    UNION ALL
    SELECT provider_id, provider_name
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  )
  GROUP BY provider_id
),
combined AS (
  SELECT
    o.provider_id,
    o.avg_outpatient,
    i.avg_inpatient,
    (o.avg_outpatient + i.avg_inpatient) AS combined_avg
  FROM outpatient o
  JOIN inpatient i USING (provider_id)
)
SELECT
  pn.provider_name,
  ROUND(c.combined_avg, 4) AS combined_average_cost_2014
FROM combined c
JOIN provider_names pn USING (provider_id)
ORDER BY combined_avg DESC
LIMIT 1;