SELECT
  TrafficSource,
  ROUND(MAX(MonthlyRevenue) - MIN(MonthlyRevenue), 4) AS RevenueDifference_Millions
FROM (
  SELECT
    trafficSource.source AS TrafficSource,
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date)) AS Month,
    SUM(totals.totalTransactionRevenue) / 1e6 AS MonthlyRevenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
  GROUP BY TrafficSource, Month
) AS MonthlyRevenues
WHERE TrafficSource = (
  SELECT
    trafficSource.source
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
  GROUP BY trafficSource.source
  ORDER BY SUM(totals.totalTransactionRevenue) DESC
  LIMIT 1
)
GROUP BY TrafficSource