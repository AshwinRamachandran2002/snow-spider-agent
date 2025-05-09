WITH year_revenue AS (
  -- total revenue (in micros) per traffic source for 2017
  SELECT
    trafficSource.source                         AS source,
    SUM(COALESCE(totals.totalTransactionRevenue,0)) AS rev_micro_year
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
  GROUP BY source
),
top_source AS (
  -- the single traffic source with the highest yearly revenue
  SELECT source
  FROM year_revenue
  ORDER BY rev_micro_year DESC
  LIMIT 1
),
monthly AS (
  -- monthly revenue (in micros) for that top source
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))       AS month,
    SUM(COALESCE(totals.totalTransactionRevenue,0))        AS rev_micro_month
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
    AND trafficSource.source = (SELECT source FROM top_source)
  GROUP BY month
)
SELECT
  (SELECT source FROM top_source)                                         AS top_traffic_source,
  ROUND( (MAX(rev_micro_month) - MIN(rev_micro_month)) / 1e12 , 2)        AS diff_monthly_revenue_millions
FROM monthly;