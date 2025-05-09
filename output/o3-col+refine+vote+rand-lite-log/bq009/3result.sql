-- Traffic source with the highest 2017 revenue and the
-- difference (in millions) between its highest and lowest-revenue months
WITH yearly AS (
  SELECT
    trafficSource.source                     AS source,
    SUM(totals.totalTransactionRevenue)      AS total_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE totals.totalTransactionRevenue IS NOT NULL
  GROUP BY source
),
top_source AS (
  SELECT source
  FROM yearly
  ORDER BY total_revenue DESC
  LIMIT 1
),
monthly AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', `date`)) AS month,
    SUM(totals.totalTransactionRevenue)               AS monthly_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`, top_source
  WHERE trafficSource.source = top_source.source
  GROUP BY month
),
diff AS (
  SELECT
    (MAX(monthly_revenue) - MIN(monthly_revenue)) / 1e6 AS diff_millions
  FROM monthly
)
SELECT
  (SELECT source FROM top_source)    AS top_traffic_source,
  ROUND(diff_millions, 2)            AS revenue_diff_millions
FROM diff;