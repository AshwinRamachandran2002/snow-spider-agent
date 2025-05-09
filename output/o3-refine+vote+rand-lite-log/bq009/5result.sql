WITH monthly_revenue AS (
  SELECT
    trafficSource.source                                     AS traffic_source,
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))         AS month,
    SUM(IFNULL(totals.totalTransactionRevenue, 0))/1e6       AS monthly_revenue   -- in millions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  GROUP BY traffic_source, month
),
source_summary AS (
  SELECT
    m.traffic_source,
    SUM(m.monthly_revenue) AS annual_revenue,          -- total 2017 revenue
    MAX(m.monthly_revenue) AS max_monthly_revenue,
    MIN(m.monthly_revenue) AS min_monthly_revenue
  FROM monthly_revenue m
  GROUP BY m.traffic_source
)
SELECT
  traffic_source,
  ROUND(max_monthly_revenue - min_monthly_revenue, 2) AS revenue_difference_millions
FROM source_summary
ORDER BY annual_revenue DESC
LIMIT 1;