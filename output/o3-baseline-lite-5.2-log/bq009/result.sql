-- Traffic source with the highest total transaction revenue in 2017
-- and the difference (in millions, rounded to 2 d.p.) between its
-- highest‑revenue month and lowest‑revenue month in 2017
WITH top_source AS (
  SELECT
    trafficSource.source AS source,
    SUM(IFNULL(totals.totalTransactionRevenue,0))            AS total_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  GROUP BY source
  ORDER BY total_rev DESC
  LIMIT 1
),
monthly_revenue AS (
  SELECT
    ts.source,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date))          AS year_month,
    SUM(IFNULL(totals.totalTransactionRevenue,0))            AS month_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  JOIN top_source ts
    ON trafficSource.source = ts.source
  GROUP BY ts.source, year_month
),
stats AS (
  SELECT
    source,
    MAX(month_rev) AS max_month_rev,
    MIN(month_rev) AS min_month_rev
  FROM monthly_revenue
  GROUP BY source
)
SELECT
  source                                                AS traffic_source,
  ROUND( (max_month_rev - min_month_rev)/1e6 , 2)       AS diff_revenue_millions
FROM stats;