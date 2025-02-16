-- Task: Which traffic source has the highest total transaction revenue in 2017?
SELECT
    trafficSource.source AS source,
    SUM(totals.totalTransactionRevenue) AS total_revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE totals.totalTransactionRevenue IS NOT NULL
GROUP BY source
ORDER BY total_revenue DESC
LIMIT 1