SELECT
  TrafficSource,
  ROUND(MAX(MonthlyRevenue) - MIN(MonthlyRevenue), 4) AS RevenueDifference_Millions
FROM (
  SELECT
    trafficSource.source AS TrafficSource,
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date)) AS Month,
    SUM(totals.totalTransactionRevenue) / 1e6 AS MonthlyRevenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE date BETWEEN '20170101' AND '20171231'
    AND totals.totalTransactionRevenue IS NOT NULL
  GROUP BY TrafficSource, Month
)
GROUP BY TrafficSource
ORDER BY SUM(MonthlyRevenue) DESC
LIMIT 1;