WITH top_source AS (
  SELECT
    trafficSource.source,
    trafficSource.medium,
    SUM(totals.totalTransactionRevenue) AS total_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND totals.totalTransactionRevenue IS NOT NULL
  GROUP BY
    trafficSource.source,
    trafficSource.medium
  ORDER BY total_revenue DESC
  LIMIT 1
),
monthly_revenue AS (
  SELECT
    'Monthly' AS Time_Frame,
    ROUND(MAX(monthly_revenue) / 1e12, 4) AS Maximum_Product_Revenue_In_Millions
  FROM (
    SELECT
      SUBSTR(date, 1, 6) AS month,
      SUM(totals.totalTransactionRevenue) AS monthly_revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE
      _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
      AND totals.totalTransactionRevenue IS NOT NULL
      AND trafficSource.source = (SELECT source FROM top_source)
      AND trafficSource.medium = (SELECT medium FROM top_source)
    GROUP BY month
  )
),
weekly_revenue AS (
  SELECT
    'Weekly' AS Time_Frame,
    ROUND(MAX(weekly_revenue) / 1e12, 4) AS Maximum_Product_Revenue_In_Millions
  FROM (
    SELECT
      EXTRACT(ISOWEEK FROM PARSE_DATE('%Y%m%d', date)) AS week,
      SUM(totals.totalTransactionRevenue) AS weekly_revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE
      _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
      AND totals.totalTransactionRevenue IS NOT NULL
      AND trafficSource.source = (SELECT source FROM top_source)
      AND trafficSource.medium = (SELECT medium FROM top_source)
    GROUP BY week
  )
),
daily_revenue AS (
  SELECT
    'Daily' AS Time_Frame,
    ROUND(MAX(daily_revenue) / 1e12, 4) AS Maximum_Product_Revenue_In_Millions
  FROM (
    SELECT
      date,
      SUM(totals.totalTransactionRevenue) AS daily_revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE
      _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
      AND totals.totalTransactionRevenue IS NOT NULL
      AND trafficSource.source = (SELECT source FROM top_source)
      AND trafficSource.medium = (SELECT medium FROM top_source)
    GROUP BY date
  )
)
SELECT * FROM monthly_revenue
UNION ALL
SELECT * FROM weekly_revenue
UNION ALL
SELECT * FROM daily_revenue
ORDER BY Time_Frame DESC;