WITH top_source AS (
  SELECT trafficSource.source AS source
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
    AND totals.totalTransactionRevenue IS NOT NULL
  GROUP BY source
  ORDER BY SUM(totals.totalTransactionRevenue) DESC
  LIMIT 1
),
monthly AS (
  SELECT
    SUBSTR(date,1,6) AS ym,
    SUM(totals.totalTransactionRevenue) AS revenue_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`, top_source
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
    AND trafficSource.source = top_source.source
    AND totals.totalTransactionRevenue IS NOT NULL
  GROUP BY ym
)
SELECT
  (SELECT source FROM top_source) AS traffic_source,
  ROUND((MAX(revenue_micro) - MIN(revenue_micro)) / 1e6, 2) AS monthly_revenue_difference_millions
FROM monthly;