WITH sessions AS (
  -- take all 2017 session tables, keep only rows where a transaction occurred
  SELECT
    trafficSource.source                         AS traffic_source,
    totals.totalTransactionRevenue               AS revenue_micro,   -- value in millionths
    PARSE_DATE('%Y%m%d', date)                   AS session_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE totals.totalTransactionRevenue IS NOT NULL
),

-- find the traffic source that generated the highest total revenue in 2017
top_source AS (
  SELECT
    traffic_source,
    SUM(revenue_micro) AS year_revenue_micro
  FROM sessions
  GROUP BY traffic_source
  ORDER BY year_revenue_micro DESC
  LIMIT 1
),

-- monthly revenue for the top traffic source
monthly_revenue AS (
  SELECT
    s.traffic_source,
    EXTRACT(MONTH FROM session_date)            AS month,
    SUM(revenue_micro)                          AS month_revenue_micro
  FROM sessions s
  JOIN top_source t
  ON  s.traffic_source = t.traffic_source
  GROUP BY s.traffic_source, month
),

-- get the highest and lowest‑revenue months for that source
extremes AS (
  SELECT
    traffic_source,
    MAX(month_revenue_micro) AS max_month_micro,
    MIN(month_revenue_micro) AS min_month_micro
  FROM monthly_revenue
  GROUP BY traffic_source
)

SELECT
  traffic_source,
  ROUND((max_month_micro - min_month_micro) / 1e12, 2) AS difference_in_millions
FROM extremes;