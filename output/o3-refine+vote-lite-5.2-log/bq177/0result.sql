WITH
/* --------------------  Inpatient (2011‑2015)  -------------------- */
inpatient AS (
  SELECT
    provider_id,
    CAST(_TABLE_SUFFIX AS INT64) AS year,
    average_medicare_payments * total_discharges AS inpatient_cost
  FROM
    `bigquery-public-data.cms_medicare.inpatient_charges_20*`
  WHERE
    _TABLE_SUFFIX IN ('2011','2012','2013','2014','2015')
),

/* total inpatient Medicare cost (2011‑2015) per provider */
inpatient_tot AS (
  SELECT
    provider_id,
    SUM(inpatient_cost) AS total_inpatient_cost_11_15
  FROM inpatient
  GROUP BY provider_id
),

/* provider with the highest total inpatient cost */
top_provider AS (
  SELECT provider_id
  FROM inpatient_tot
  ORDER BY total_inpatient_cost_11_15 DESC
  LIMIT 1
),

/* yearly average inpatient cost for that provider */
yearly_inpatient AS (
  SELECT
    provider_id,
    year,
    AVG(inpatient_cost) AS avg_inpatient_cost
  FROM inpatient
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
  GROUP BY provider_id, year
),

/* --------------------  Outpatient (2011‑2015)  -------------------- */
outpatient AS (
  SELECT
    provider_id,
    CAST(_TABLE_SUFFIX AS INT64) AS year,
    average_total_payments * outpatient_services AS outpatient_cost
  FROM
    `bigquery-public-data.cms_medicare.outpatient_charges_20*`
  WHERE
    _TABLE_SUFFIX IN ('2011','2012','2013','2014','2015')
),

/* yearly average outpatient cost for the same provider */
yearly_outpatient AS (
  SELECT
    provider_id,
    year,
    AVG(outpatient_cost) AS avg_outpatient_cost
  FROM outpatient
  WHERE provider_id IN (SELECT provider_id FROM top_provider)
  GROUP BY provider_id, year
),

/* calendar years to guarantee one row per year */
years AS (
  SELECT 2011 AS year UNION ALL
  SELECT 2012 UNION ALL
  SELECT 2013 UNION ALL
  SELECT 2014 UNION ALL
  SELECT 2015
)

/* --------------------  Final result -------------------- */
SELECT
  COALESCE(i.provider_id, o.provider_id) AS provider_id,
  y.year,
  ROUND(i.avg_inpatient_cost ,4)  AS avg_inpatient_cost,
  ROUND(o.avg_outpatient_cost,4)  AS avg_outpatient_cost
FROM years AS y
LEFT JOIN yearly_inpatient  AS i ON i.year = y.year
LEFT JOIN yearly_outpatient AS o ON o.year = y.year
ORDER BY y.year;