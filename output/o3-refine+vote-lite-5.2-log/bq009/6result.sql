-- traffic source with highest 2017 revenue
WITH revenue_by_source AS (
  SELECT
    trafficSource.source                                  AS source,
    SUM(IFNULL(totals.totalTransactionRevenue,0))         AS total_rev_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'   -- keep 2017 daily tables
  GROUP BY source
),
top_source AS (
  SELECT source
  FROM revenue_by_source
  ORDER BY total_rev_micro DESC
  LIMIT 1                                                 -- highest‑revenue source
),
monthly_revenue AS (
  SELECT
    SUBSTR(date,1,6)                                      AS year_month,          -- YYYYMM
    SUM(IFNULL(totals.totalTransactionRevenue,0))         AS rev_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
    AND trafficSource.source IN (SELECT source FROM top_source)
  GROUP BY year_month
)

SELECT
  (SELECT source FROM top_source)                         AS traffic_source,
  ROUND((MAX(rev_micro) - MIN(rev_micro)) / 1e12, 2)      AS difference_in_millions
FROM monthly_revenue;