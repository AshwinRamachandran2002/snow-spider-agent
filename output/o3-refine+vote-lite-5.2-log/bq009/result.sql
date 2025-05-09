-- Traffic source with the highest 2017 revenue and the gap (in millions) 
-- between its best‑ and worst‑performing month
WITH session_data AS (
  SELECT
    trafficSource.source                            AS source,
    totals.totalTransactionRevenue                  AS revenue_micro,      -- value in micros
    PARSE_DATE('%Y%m%d', date)                      AS session_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE totals.totalTransactionRevenue IS NOT NULL
),
monthly_revenue AS (
  SELECT
    source,
    EXTRACT(MONTH FROM session_date)                AS month,
    SUM(revenue_micro)                              AS month_revenue_micro
  FROM session_data
  GROUP BY source, month
),
source_level AS (
  SELECT
    source,
    SUM(month_revenue_micro)                        AS year_revenue_micro,
    MAX(month_revenue_micro)                        AS max_month_micro,
    MIN(month_revenue_micro)                        AS min_month_micro
  FROM monthly_revenue
  GROUP BY source
),
top_source AS (
  SELECT *
  FROM source_level
  ORDER BY year_revenue_micro DESC
  LIMIT 1                                           -- traffic source with highest yearly revenue
)
SELECT
  source                                           AS traffic_source,
  ROUND( (max_month_micro - min_month_micro) / 1e12, 2 ) 
                                                  AS revenue_difference_millions
FROM top_source;