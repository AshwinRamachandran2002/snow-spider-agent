-- 1st‑half of 2017 (Jan 1 – Jun 30)
-- trafficSource.source with the highest total product revenue,
-- and its maximum DAILY, WEEKLY, MONTHLY product revenues
-- (all revenues shown in millions, i.e. micros / 1 000 000 000 000)

WITH source_totals AS (      -- total revenue per source
  SELECT
    trafficSource.source               AS source,
    SUM(p.productRevenue)              AS revenue_micros
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
  GROUP BY source
),

top_source AS (              -- the single best‑performing source
  SELECT *
  FROM   source_totals
  ORDER  BY revenue_micros DESC
  LIMIT  1
),

daily AS (                   -- daily revenue for that source
  SELECT
    trafficSource.source                              AS source,
    PARSE_DATE('%Y%m%d', s.date)                      AS day,
    SUM(p.productRevenue)                             AS revenue_micros
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
  GROUP BY source, day
),

weekly AS (                  -- week starts on Monday
  SELECT
    trafficSource.source                              AS source,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', s.date), WEEK)    AS week_start,
    SUM(p.productRevenue)                             AS revenue_micros
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
  GROUP BY source, week_start
),

monthly AS (                 -- monthly revenue
  SELECT
    trafficSource.source                              AS source,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', s.date), MONTH)   AS month_start,
    SUM(p.productRevenue)                             AS revenue_micros
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
  GROUP BY source, month_start
)

SELECT
  t.source,
  ROUND(t.revenue_micros / 1e12, 4)           AS total_revenue_millions,
  ROUND((SELECT MAX(revenue_micros) FROM daily   d WHERE d.source = t.source)/1e12, 4)
                                              AS max_daily_revenue_millions,
  ROUND((SELECT MAX(revenue_micros) FROM weekly  w WHERE w.source = t.source)/1e12, 4)
                                              AS max_weekly_revenue_millions,
  ROUND((SELECT MAX(revenue_micros) FROM monthly m WHERE m.source = t.source)/1e12, 4)
                                              AS max_monthly_revenue_millions
FROM top_source t;