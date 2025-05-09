-- Find the traffic source with the highest 2017 revenue and
-- the gap (in millions) between its best- and worst-performing months
WITH top_source AS (
  SELECT
    trafficSource.source AS source,
    SUM(totals.totalTransactionRevenue) AS total_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  GROUP BY source
  ORDER BY total_revenue DESC
  LIMIT 1
),
monthly AS (
  SELECT
    SUBSTR(_TABLE_SUFFIX,5,2)                     AS month,
    SUM(totals.totalTransactionRevenue)/1e12      AS revenue_millions   -- convert to $ millions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE trafficSource.source IN (SELECT source FROM top_source)
  GROUP BY month
)
SELECT
  (SELECT source FROM top_source)                                AS top_traffic_source,
  ROUND(MAX(revenue_millions) - MIN(revenue_millions), 2)        AS diff_between_max_min_millions
FROM monthly;