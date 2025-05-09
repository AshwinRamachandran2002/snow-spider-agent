-- Traffic source with the highest 2017 revenue
-- and the difference (in millions) between its
-- highest- and lowest-revenue months
WITH source_totals AS (
  SELECT
    trafficSource.source                       AS source,
    SUM(totals.totalTransactionRevenue)        AS revenue_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX LIKE '2017%'             -- only 2017 tables
  GROUP BY source
),
top_source AS (                               -- pick the #1 source
  SELECT source
  FROM source_totals
  ORDER BY revenue_micro DESC
  LIMIT 1
),
monthly_rev AS (                              -- monthly totals for that source
  SELECT
    SUBSTR(_TABLE_SUFFIX,1,6)                 AS year_month,      -- e.g., 201701
    SUM(totals.totalTransactionRevenue)/1e12  AS revenue_millions -- convert to $
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`, top_source
  WHERE _TABLE_SUFFIX LIKE '2017%'
    AND trafficSource.source = top_source.source
  GROUP BY year_month
)
SELECT
  (SELECT source FROM top_source)                       AS traffic_source,
  ROUND(MAX(revenue_millions) - MIN(revenue_millions), 2) AS diff_millions
FROM monthly_rev;