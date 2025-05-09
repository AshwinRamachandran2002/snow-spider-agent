/*  Jan‑Jun 2017 : top‑revenue traffic source
    and its highest daily / weekly / monthly
    product revenues (in millions)            */
WITH product_revenue AS (
  -- explode to product level and keep only rows with revenue
  SELECT
    s.trafficSource.source              AS source,
    PARSE_DATE('%Y%m%d', s.date)        AS dt,
    p.productRevenue                    AS product_revenue          -- value is in micros
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
  CROSS JOIN UNNEST(s.hits)    AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'             -- first half of 2017
    AND p.productRevenue IS NOT NULL
),
-- traffic source with the greatest overall product revenue
top_source AS (
  SELECT
    pr.source,
    SUM(pr.product_revenue) AS total_revenue
  FROM product_revenue AS pr
  GROUP BY pr.source
  ORDER BY total_revenue DESC
  LIMIT 1
),
-- keep only rows that belong to the winning source
top_source_data AS (
  SELECT pr.*
  FROM product_revenue AS pr
  JOIN top_source       AS ts
  ON  pr.source = ts.source
),
-- daily totals
daily AS (
  SELECT
    dt,
    SUM(product_revenue) AS rev
  FROM top_source_data
  GROUP BY dt
),
-- weekly totals (weeks start on Monday)
weekly AS (
  SELECT
    DATE_TRUNC(dt, WEEK(MONDAY)) AS wk_start,
    SUM(product_revenue)         AS rev
  FROM top_source_data
  GROUP BY wk_start
),
-- monthly totals
monthly AS (
  SELECT
    DATE_TRUNC(dt, MONTH) AS mon_start,
    SUM(product_revenue)  AS rev
  FROM top_source_data
  GROUP BY mon_start
)
SELECT
  (SELECT source FROM top_source)                     AS top_traffic_source,
  (SELECT MAX(rev) / 1e6 FROM daily)   AS max_daily_product_revenue_millions,
  (SELECT MAX(rev) / 1e6 FROM weekly)  AS max_weekly_product_revenue_millions,
  (SELECT MAX(rev) / 1e6 FROM monthly) AS max_monthly_product_revenue_millions;