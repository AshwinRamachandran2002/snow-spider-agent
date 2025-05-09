WITH all_hits AS (
  SELECT
    trafficSource.source                               AS source,
    PARSE_DATE('%Y%m%d', date)                        AS hit_date,
    p.productRevenue                                   AS revenue_micro    -- revenue in micro-units
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)   AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
),
-- ----------------------------------------------------
top_source AS (        -- traffic source with the highest total revenue
  SELECT source
  FROM   all_hits
  GROUP  BY source
  ORDER  BY SUM(revenue_micro) DESC
  LIMIT  1
),
-- ----------------------------------------------------
daily AS (             -- daily revenue (millions) for every source
  SELECT
    source,
    SUM(revenue_micro)/1e6 AS revenue_m
  FROM   all_hits
  GROUP  BY source, hit_date
),
weekly AS (            -- ISO-week revenue (millions) for every source
  SELECT
    source,
    SUM(revenue_micro)/1e6 AS revenue_m
  FROM   all_hits
  GROUP  BY source, FORMAT_DATE('%G-%V', hit_date)
),
monthly AS (           -- monthly revenue (millions) for every source
  SELECT
    source,
    SUM(revenue_micro)/1e6 AS revenue_m
  FROM   all_hits
  GROUP  BY source, FORMAT_DATE('%Y%m', hit_date)
)
-- ====================  final answer  ====================
SELECT
  ts.source                                                   AS top_source,
  (SELECT MAX(revenue_m) FROM daily   WHERE source = ts.source) AS max_daily_revenue_m,
  (SELECT MAX(revenue_m) FROM weekly  WHERE source = ts.source) AS max_weekly_revenue_m,
  (SELECT MAX(revenue_m) FROM monthly WHERE source = ts.source) AS max_monthly_revenue_m
FROM top_source ts;