WITH inpatient_raw AS (
  SELECT
    provider_id,
    CAST(_TABLE_SUFFIX AS INT64)                    AS year,
    average_medicare_payments * total_discharges    AS cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2015'
),
-- total in‑patient Medicare cost (2011‑2015) per provider
provider_totals AS (
  SELECT
    provider_id,
    SUM(cost) AS total_inpatient_cost
  FROM inpatient_raw
  GROUP BY provider_id
),
-- provider with the highest 2011‑2015 in‑patient cost
top_provider AS (
  SELECT provider_id
  FROM provider_totals
  ORDER BY total_inpatient_cost DESC
  LIMIT 1
),
/* yearly average in‑patient cost for the top provider */
yearly_inpatient AS (
  SELECT
    ir.year,
    AVG(ir.cost) AS avg_inpatient_cost
  FROM inpatient_raw ir
  JOIN top_provider tp USING (provider_id)
  GROUP BY ir.year
),
/* outpatient cost rows (2011‑2015) */
outpatient_raw AS (
  SELECT
    provider_id,
    CAST(_TABLE_SUFFIX AS INT64)                    AS year,
    average_total_payments * outpatient_services    AS cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2015'
),
/* yearly average out‑patient cost for the top provider */
yearly_outpatient AS (
  SELECT
    oraw.year,
    AVG(oraw.cost) AS avg_outpatient_cost
  FROM outpatient_raw oraw
  JOIN top_provider tp USING (provider_id)
  GROUP BY oraw.year
)
SELECT
  tp.provider_id,
  yi.year,
  yi.avg_inpatient_cost,
  yo.avg_outpatient_cost
FROM top_provider tp
JOIN yearly_inpatient yi ON TRUE
LEFT JOIN yearly_outpatient yo USING (year)
ORDER BY yi.year;