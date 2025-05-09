WITH revenue_by_source AS (
  -- 1.  Total 2017 revenue per traffic source
  SELECT
    trafficSource.source                           AS source,
    SUM(totals.totalTransactionRevenue)            AS total_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
        AND totals.totalTransactionRevenue IS NOT NULL
  GROUP BY source
),
top_source AS (
  -- 2.  Pick the revenue-leading source
  SELECT source
  FROM revenue_by_source
  ORDER BY total_rev DESC
  LIMIT 1
),
monthly_revenue AS (
  -- 3.  Month-by-month revenue for that top source
  SELECT
    SUBSTR(date,1,6)                               AS yyyymm,
    SUM(totals.totalTransactionRevenue)            AS monthly_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
        AND totals.totalTransactionRevenue IS NOT NULL
        AND trafficSource.source = (SELECT source FROM top_source)
  GROUP BY yyyymm
),
bounds AS (
  -- 4.  Find max and min monthly revenue
  SELECT
    MAX(monthly_rev) AS max_rev,
    MIN(monthly_rev) AS min_rev
  FROM monthly_revenue
)
-- 5.  Final answer
SELECT
  (SELECT source FROM top_source)                  AS traffic_source,
  ROUND( (max_rev - min_rev) / 1e6 , 2)            AS diff_in_millions
FROM bounds;