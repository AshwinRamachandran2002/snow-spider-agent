/* 1H‑2017 ‑ top trafficSource.source by product revenue
   and its max daily / weekly / monthly revenues (in $‑millions) */

WITH product_revenue AS (
  SELECT
    s.trafficSource.source         AS source,
    PARSE_DATE('%Y%m%d', s.date)   AS session_date,
    -- micros ➜ dollars ➜ millions
    product.productRevenue / 1e12  AS revenue_million
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
  CROSS JOIN UNNEST(s.hits)    AS hit
  CROSS JOIN UNNEST(hit.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND product.productRevenue IS NOT NULL
),
source_totals AS (
  SELECT source,
         SUM(revenue_million) AS total_revenue_million
  FROM product_revenue
  GROUP BY source
),
top_source AS (
  SELECT source, total_revenue_million
  FROM   source_totals
  ORDER  BY total_revenue_million DESC
  LIMIT  1
),
daily_rev AS (
  SELECT session_date,
         SUM(revenue_million) AS daily_revenue_million
  FROM   product_revenue
  WHERE  source = (SELECT source FROM top_source)
  GROUP  BY session_date
),
weekly_rev AS (
  SELECT DATE_TRUNC(session_date, WEEK(MONDAY)) AS week_start,
         SUM(revenue_million)                   AS weekly_revenue_million
  FROM   product_revenue
  WHERE  source = (SELECT source FROM top_source)
  GROUP  BY week_start
),
monthly_rev AS (
  SELECT DATE_TRUNC(session_date, MONTH)        AS month_start,
         SUM(revenue_million)                   AS monthly_revenue_million
  FROM   product_revenue
  WHERE  source = (SELECT source FROM top_source)
  GROUP  BY month_start
)

SELECT
    t.source                                                          AS traffic_source,
    ROUND(t.total_revenue_million          , 4)                       AS total_revenue_millions,
    ROUND((SELECT MAX(daily_revenue_million)  FROM daily_rev)  , 4)   AS max_daily_revenue_millions,
    ROUND((SELECT MAX(weekly_revenue_million) FROM weekly_rev) , 4)   AS max_weekly_revenue_millions,
    ROUND((SELECT MAX(monthly_revenue_million) FROM monthly_rev), 4)  AS max_monthly_revenue_millions
FROM top_source AS t;