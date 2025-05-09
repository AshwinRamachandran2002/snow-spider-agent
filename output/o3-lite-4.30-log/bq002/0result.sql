WITH base AS (
  -- product‑level revenue for Jan‑Jun 2017 (micro‑units)
  SELECT
    trafficSource.source                                   AS traffic_source,
    date,
    FORMAT_DATE('%G-%V', PARSE_DATE('%Y%m%d', date))       AS iso_week,
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))       AS ym,
    p.productRevenue                                       AS revenue_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)    AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
),

-- total revenue per traffic source; keep the top one
top_source AS (
  SELECT
    traffic_source,
    SUM(revenue_micro) AS total_revenue_micro
  FROM base
  GROUP BY traffic_source
  ORDER BY total_revenue_micro DESC
  LIMIT 1
),

-- rows only for the top‑performing source
scoped AS (
  SELECT b.*
  FROM base AS b
  JOIN top_source USING (traffic_source)
),

-- daily, weekly, monthly sums
daily   AS (SELECT date,     SUM(revenue_micro) AS day_revenue_micro   FROM scoped GROUP BY date),
weekly  AS (SELECT iso_week, SUM(revenue_micro) AS week_revenue_micro  FROM scoped GROUP BY iso_week),
monthly AS (SELECT ym,       SUM(revenue_micro) AS month_revenue_micro FROM scoped GROUP BY ym)

SELECT
  ts.traffic_source,
  ROUND(ts.total_revenue_micro              / 1e12, 4) AS total_product_revenue_millions,
  ROUND((SELECT MAX(day_revenue_micro)   FROM daily)   / 1e12, 4) AS max_daily_product_revenue_millions,
  ROUND((SELECT MAX(week_revenue_micro)  FROM weekly)  / 1e12, 4) AS max_weekly_product_revenue_millions,
  ROUND((SELECT MAX(month_revenue_micro) FROM monthly) / 1e12, 4) AS max_monthly_product_revenue_millions
FROM top_source AS ts;