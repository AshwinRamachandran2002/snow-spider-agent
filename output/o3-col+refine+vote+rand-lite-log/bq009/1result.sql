WITH yearly AS (
  -- total transaction revenue (in micro-units) by traffic source for 2017
  SELECT
    trafficSource.source                            AS source,
    SUM(IFNULL(totals.totalTransactionRevenue,0))   AS micro_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
  GROUP BY source
),
top_source AS (
  -- pick the traffic source with the highest yearly revenue
  SELECT source
  FROM yearly
  ORDER BY micro_rev DESC
  LIMIT 1
),
monthly AS (
  -- monthly revenue (in millions) for that top traffic source
  SELECT
    SUBSTR(date,1,6)                                AS yyyymm,
    SUM(IFNULL(totals.totalTransactionRevenue,0))/1e6 AS revenue_millions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`, top_source
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
    AND trafficSource.source = top_source.source
  GROUP BY yyyymm
)
-- final answer: top traffic source and the difference between its max & min monthly revenue
SELECT
  (SELECT source FROM top_source)                       AS highest_revenue_source,
  ROUND(MAX(revenue_millions) - MIN(revenue_millions), 2) AS difference_millions
FROM monthly;