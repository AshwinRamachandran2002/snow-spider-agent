WITH inpatient_yearly AS (
  SELECT
    CAST(CONCAT('20', _TABLE_SUFFIX) AS INT64)                           AS year,
    provider_id,
    AVG(average_medicare_payments * total_discharges)                   AS avg_inpatient_cost,
    SUM(average_medicare_payments * total_discharges)                   AS total_inpatient_cost
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_20*`
  WHERE _TABLE_SUFFIX BETWEEN '11' AND '15'     -- years 2011‑2015
  GROUP BY year, provider_id
),
provider_totals AS (
  SELECT
    provider_id,
    SUM(total_inpatient_cost)                                           AS five_year_inpatient_cost,
    RANK() OVER (ORDER BY SUM(total_inpatient_cost) DESC)               AS rnk
  FROM inpatient_yearly
  GROUP BY provider_id
),
top_provider AS (
  SELECT provider_id
  FROM   provider_totals
  WHERE  rnk = 1
),
outpatient_yearly AS (
  SELECT
    CAST(CONCAT('20', _TABLE_SUFFIX) AS INT64)                           AS year,
    provider_id,
    AVG(average_total_payments * outpatient_services)                   AS avg_outpatient_cost
  FROM `bigquery-public-data.cms_medicare.outpatient_charges_20*`
  WHERE _TABLE_SUFFIX BETWEEN '11' AND '15'
  GROUP BY year, provider_id
),
years AS (
  SELECT year
  FROM UNNEST(GENERATE_ARRAY(2011, 2015)) AS year
)

SELECT
  tp.provider_id,
  y.year                                                 AS calendar_year,
  i.avg_inpatient_cost,
  o.avg_outpatient_cost
FROM top_provider tp
CROSS JOIN years y
LEFT JOIN inpatient_yearly  i  ON i.provider_id = tp.provider_id AND i.year = y.year
LEFT JOIN outpatient_yearly o  ON o.provider_id = tp.provider_id AND o.year = y.year
ORDER BY calendar_year;