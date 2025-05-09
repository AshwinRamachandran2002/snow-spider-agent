WITH revenue_per_source AS (
  SELECT
    trafficSource.source AS source,
    SUM(totals.totalTransactionRevenue) AS revenue_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX LIKE '2017%'
    AND totals.totalTransactionRevenue IS NOT NULL
  GROUP BY source
),
top_source AS (
  SELECT source
  FROM revenue_per_source
  ORDER BY revenue_micro DESC
  LIMIT 1
),
monthly_revenue AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS yr_month,
    SUM(totals.totalTransactionRevenue) AS revenue_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`, top_source
  WHERE _TABLE_SUFFIX LIKE '2017%'
    AND totals.totalTransactionRevenue IS NOT NULL
    AND trafficSource.source = top_source.source
  GROUP BY yr_month
),
difference AS (
  SELECT
    ROUND((MAX(revenue_micro) - MIN(revenue_micro)) / 1e12, 2) AS diff_millions
  FROM monthly_revenue
)
SELECT
  (SELECT source FROM top_source) AS traffic_source,
  diff_millions                 AS monthly_revenue_difference_millions
FROM difference;