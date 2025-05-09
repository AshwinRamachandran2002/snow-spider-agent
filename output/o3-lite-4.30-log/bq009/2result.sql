WITH sessions_2017 AS (
  SELECT
    trafficSource.source           AS source,
    totals.totalTransactionRevenue AS revenue_micro,
    SUBSTR(date, 1, 6)             AS yyyymm          -- YYYYMM
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE totals.totalTransactionRevenue IS NOT NULL
),
top_source AS (
  SELECT source
  FROM sessions_2017
  GROUP BY source
  ORDER BY SUM(revenue_micro) DESC
  LIMIT 1
),
monthly_revenue AS (
  SELECT
    yyyymm,
    SUM(revenue_micro) / 1e12 AS revenue_millions    -- micro‑units → millions
  FROM sessions_2017
  WHERE source IN (SELECT source FROM top_source)
  GROUP BY yyyymm
)
SELECT
  (SELECT source FROM top_source) AS traffic_source,
  ROUND(MAX(revenue_millions) - MIN(revenue_millions), 2) AS monthly_revenue_difference_millions
FROM monthly_revenue;