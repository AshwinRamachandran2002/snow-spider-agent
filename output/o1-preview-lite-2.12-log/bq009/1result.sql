WITH total_revenue_by_source AS (
  SELECT
    trafficSource.source AS source,
    SUM(totals.totalTransactionRevenue) AS total_revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
    AND totals.totalTransactionRevenue IS NOT NULL
    AND trafficSource.source IS NOT NULL
    AND trafficSource.source != ''
  GROUP BY
    source
  ORDER BY
    total_revenue DESC
  LIMIT 1
),
monthly_revenues AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.totalTransactionRevenue) AS monthly_revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
    AND trafficSource.source = (SELECT source FROM total_revenue_by_source)
    AND totals.totalTransactionRevenue IS NOT NULL
  GROUP BY
    month
)
SELECT
  (SELECT source FROM total_revenue_by_source) AS Traffic_Source,
  ROUND((MAX(monthly_revenue) - MIN(monthly_revenue))/1e6, 2) AS Revenue_Difference_in_Millions
FROM
  monthly_revenues;