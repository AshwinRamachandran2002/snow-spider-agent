WITH period_data AS (
  -- 1.  All product-revenue hits during Jan 1 – Jun 30 2017
  SELECT
    trafficSource.source            AS source,
    date,
    p.productRevenue / 1e6          AS revenue_million          -- scale to millions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)      AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
),
top_source AS (
  -- 2.  Traffic source with the highest total revenue
  SELECT source
  FROM period_data
  GROUP BY source
  ORDER BY SUM(revenue_million) DESC
  LIMIT 1
),
daily AS (
  -- 3a. Daily revenue for that top source
  SELECT date, SUM(revenue_million) AS day_rev
  FROM period_data
  WHERE source = (SELECT source FROM top_source)
  GROUP BY date
),
weekly AS (
  -- 3b. Weekly (ISO-week) revenue
  SELECT FORMAT_DATE('%G%V', PARSE_DATE('%Y%m%d', date)) AS iso_week,
         SUM(revenue_million)                           AS week_rev
  FROM period_data
  WHERE source = (SELECT source FROM top_source)
  GROUP BY iso_week
),
monthly AS (
  -- 3c. Monthly revenue (YYYYMM)
  SELECT SUBSTR(date, 1, 6) AS month,
         SUM(revenue_million) AS month_rev
  FROM period_data
  WHERE source = (SELECT source FROM top_source)
  GROUP BY month
)
-- 4.  Report the required maximums
SELECT
  (SELECT source     FROM top_source)  AS top_source,
  (SELECT MAX(day_rev)   FROM daily)   AS max_daily_revenue_million,
  (SELECT MAX(week_rev)  FROM weekly)  AS max_weekly_revenue_million,
  (SELECT MAX(month_rev) FROM monthly) AS max_monthly_revenue_million;