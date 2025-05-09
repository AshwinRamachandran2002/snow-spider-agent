-- provider with greatest total inpatient Medicare cost, then yearly avg inpatient & outpatient costs
WITH
/* ----------  Inpatient (2011‑2015)  ---------- */
inpatient AS (
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX,1,4) AS INT64)           AS year,
    provider_id,                                       -- STRING
    average_medicare_payments * total_discharges       AS cost_per_drg
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2015'
),

/* total 5‑year inpatient cost per provider */
prov_5yr_inpatient_tot AS (
  SELECT
    provider_id,
    SUM(cost_per_drg) AS five_year_total_inpatient_cost
  FROM inpatient
  GROUP BY provider_id
),

/* provider with highest 5‑year inpatient cost */
top_provider AS (
  SELECT provider_id
  FROM prov_5yr_inpatient_tot
  ORDER BY five_year_total_inpatient_cost DESC
  LIMIT 1
),

/* yearly AVG inpatient cost for that provider */
inpatient_yearly AS (
  SELECT
    year,
    AVG(cost_per_drg) AS avg_inpatient_cost
  FROM inpatient
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  GROUP BY year
),

/* ----------  Outpatient (2011‑2015)  ---------- */
outpatient AS (
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX,1,4) AS INT64)              AS year,
    provider_id,
    average_total_payments * outpatient_services          AS cost_per_apc
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2015'
),

/* yearly AVG outpatient cost for the same provider */
outpatient_yearly AS (
  SELECT
    year,
    AVG(cost_per_apc) AS avg_outpatient_cost
  FROM outpatient
  WHERE provider_id = (SELECT provider_id FROM top_provider)
  GROUP BY year
)

/* ----------  Final result  ---------- */
SELECT
  y.year,
  i.avg_inpatient_cost,
  o.avg_outpatient_cost
FROM (
  SELECT DISTINCT year FROM inpatient_yearly
  UNION DISTINCT
  SELECT DISTINCT year FROM outpatient_yearly
) AS y
LEFT JOIN inpatient_yearly  AS i USING (year)
LEFT JOIN outpatient_yearly AS o USING (year)
ORDER BY year;