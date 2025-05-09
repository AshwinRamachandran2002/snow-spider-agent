WITH TopTrafficSource AS (
  SELECT
    trafficSource.source AS Traffic_Source,
    SUM(totals.transactionRevenue) AS Total_Revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE STARTS_WITH(_TABLE_SUFFIX, '2017')
    AND totals.transactionRevenue IS NOT NULL
  GROUP BY Traffic_Source
  ORDER BY Total_Revenue DESC
  LIMIT 1
),
MonthlyRevenue AS (
  SELECT
    SUBSTR(date, 1, 6) AS month,
    SUM(totals.transactionRevenue) AS monthly_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE STARTS_WITH(_TABLE_SUFFIX, '2017')
    AND totals.transactionRevenue IS NOT NULL
    AND trafficSource.source = (SELECT Traffic_Source FROM TopTrafficSource)
  GROUP BY month
)
SELECT
  (SELECT Traffic_Source FROM TopTrafficSource) AS Traffic_Source,
  ROUND(ABS(MAX(monthly_revenue) - MIN(monthly_revenue)) / 1000000, 4) AS Revenue_Difference_in_Millions
FROM MonthlyRevenue;