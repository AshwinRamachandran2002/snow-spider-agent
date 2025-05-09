WITH yearly AS (
  SELECT
    trafficSource.source AS source,
    SUM(totals.totalTransactionRevenue) AS total_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE totals.totalTransactionRevenue IS NOT NULL
  GROUP BY source
),
top_source AS (
  SELECT source
  FROM yearly
  ORDER BY total_rev DESC
  LIMIT 1
),
monthly AS (
  SELECT
    SUBSTR(date, 1, 6) AS yyyymm,
    SUM(totals.totalTransactionRevenue) AS monthly_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`, top_source
  WHERE totals.totalTransactionRevenue IS NOT NULL
    AND trafficSource.source = top_source.source
  GROUP BY yyyymm
),
bounds AS (
  SELECT
    MAX(monthly_rev) AS max_rev,
    MIN(monthly_rev) AS min_rev
  FROM monthly
)
SELECT
  (SELECT source FROM top_source) AS top_traffic_source,
  ROUND((max_rev - min_rev) / 1e6, 2) AS diff_in_millions
FROM bounds;