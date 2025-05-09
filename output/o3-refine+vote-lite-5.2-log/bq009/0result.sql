-- traffic source with highest 2017 revenue and the spread between its best and worst months
WITH sessions_2017 AS (
  SELECT
    PARSE_DATE('%Y%m%d', `date`)              AS session_date,
    trafficSource.source                      AS source,
    totals.totalTransactionRevenue            AS revenue_micro  -- value is in micros
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE totals.totalTransactionRevenue IS NOT NULL
),
source_yearly AS (
  SELECT
    source,
    SUM(revenue_micro) AS yearly_revenue_micro
  FROM sessions_2017
  GROUP BY source
),
top_source AS (      -- pick the traffic source with the highest total revenue
  SELECT source
  FROM source_yearly
  ORDER BY yearly_revenue_micro DESC
  LIMIT 1
),
monthly_totals AS (   -- monthly revenue (in millions) for the top source
  SELECT
    source,
    FORMAT_DATE('%Y-%m', session_date)                AS year_month,
    SUM(revenue_micro) / 1e6                          AS month_revenue_million
  FROM sessions_2017
  WHERE source = (SELECT source FROM top_source)
  GROUP BY source, year_month
),
min_max AS (
  SELECT
    source,
    MAX(month_revenue_million) AS max_month,
    MIN(month_revenue_million) AS min_month
  FROM monthly_totals
  GROUP BY source
)
SELECT
  source                                                AS traffic_source,
  ROUND(max_month - min_month, 2)                       AS revenue_diff_million
FROM min_max;