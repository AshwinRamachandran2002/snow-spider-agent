SELECT
  '(direct)' AS Traffic_Source,
  ROUND((MAX(monthly_revenue) - MIN(monthly_revenue))/1000000, 2) AS Revenue_Difference_in_Millions
FROM (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', `date`)) AS month,
    SUM(totals.transactionRevenue) AS monthly_revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
    AND trafficSource.source = '(direct)'
  GROUP BY
    month
)