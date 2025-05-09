WITH base AS (
  -- sessions from Jan‑01 to Jun‑30 2017 with product‑level revenue
  SELECT
    PARSE_DATE('%Y%m%d', date)                       AS session_date,
    trafficSource.source                             AS source,
    CAST(p.productRevenue AS NUMERIC) / 1e12         AS revenue_millions   -- convert micro‑units → millions
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits)   h,
        UNNEST(h.product) p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
),
-- total revenue by traffic source in H1‑2017
source_totals AS (
  SELECT
    source,
    SUM(revenue_millions) AS total_revenue_millions
  FROM base
  GROUP BY source
),
-- the #1 revenue‑generating source
top_source AS (
  SELECT source
  FROM source_totals
  ORDER BY total_revenue_millions DESC
  LIMIT 1
),
-- daily, weekly, monthly revenue for that source
daily AS (
  SELECT session_date,
         SUM(revenue_millions) AS revenue_millions
  FROM base
  JOIN top_source USING (source)
  GROUP BY session_date
),
weekly AS (
  SELECT DATE_TRUNC(session_date, WEEK(MONDAY)) AS week_start,
         SUM(revenue_millions)                 AS revenue_millions
  FROM base
  JOIN top_source USING (source)
  GROUP BY week_start
),
monthly AS (
  SELECT DATE_TRUNC(session_date, MONTH)        AS month_start,
         SUM(revenue_millions)                 AS revenue_millions
  FROM base
  JOIN top_source USING (source)
  GROUP BY month_start
)

SELECT
  (SELECT source FROM top_source)                          AS traffic_source,
  (SELECT MAX(revenue_millions) FROM daily)   AS max_daily_revenue_millions,
  (SELECT MAX(revenue_millions) FROM weekly)  AS max_weekly_revenue_millions,
  (SELECT MAX(revenue_millions) FROM monthly) AS max_monthly_revenue_millions;