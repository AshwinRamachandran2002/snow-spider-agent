WITH source_totals AS (
  -- total 2017 revenue by traffic source
  SELECT
    trafficSource.source            AS source,
    SUM(totals.totalTransactionRevenue) AS total_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE totals.totalTransactionRevenue IS NOT NULL
  GROUP BY source
),
top_source AS (
  -- pick the source with the highest 2017 revenue
  SELECT source
  FROM source_totals
  ORDER BY total_revenue DESC
  LIMIT 1
),
monthly AS (
  -- month-by-month revenue for that top source
  SELECT
    SUBSTR(date,1,6)                AS year_month,
    SUM(totals.totalTransactionRevenue) AS monthly_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE totals.totalTransactionRevenue IS NOT NULL
    AND trafficSource.source = (SELECT source FROM top_source)
  GROUP BY year_month
)
-- final answer
SELECT
  (SELECT source FROM top_source)               AS traffic_source,
  ROUND( (MAX(monthly_revenue) - MIN(monthly_revenue)) / 1e6 , 2) AS diff_millions
FROM monthly;