-- 1st half of 2017 (Jan‑01 → Jun‑30)
-- Find the trafficSource.source that produces the most product revenue,
-- then show the greatest daily, weekly and monthly revenues (in millions)
-- that this source achieved during that period
WITH revenues AS (
  SELECT
    trafficSource.source                           AS source,
    PARSE_DATE('%Y%m%d', date)                     AS session_date,
    product.productRevenue                         AS revenue          -- micro‑units
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
       UNNEST(hits)   AS hit,
       UNNEST(hit.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0630'            -- 1H‑2017
    AND product.productRevenue IS NOT NULL
),
-- total revenue by traffic source
source_totals AS (
  SELECT source, SUM(revenue) AS total_revenue
  FROM revenues
  GROUP BY source
),
-- the single best‑performing traffic source
top_source AS (
  SELECT source
  FROM source_totals
  ORDER BY total_revenue DESC
  LIMIT 1
),
-- all revenue rows for that top source
top_source_data AS (
  SELECT r.*
  FROM revenues r
  JOIN top_source t USING (source)
),
-- daily/weekly/monthly aggregates for the top source
daily_rev AS (
  SELECT session_date                           AS period_start,
         SUM(revenue)                           AS rev
  FROM top_source_data
  GROUP BY session_date
),
weekly_rev AS (
  SELECT DATE_TRUNC(session_date, WEEK(MONDAY)) AS period_start,
         SUM(revenue)                           AS rev
  FROM top_source_data
  GROUP BY period_start
),
monthly_rev AS (
  SELECT DATE_TRUNC(session_date, MONTH)        AS period_start,
         SUM(revenue)                           AS rev
  FROM top_source_data
  GROUP BY period_start
)
SELECT
  (SELECT source FROM top_source)                       AS top_traffic_source,
  ROUND((SELECT MAX(rev) FROM daily_rev ) / 1e6 , 4)    AS max_daily_revenue_millions,
  ROUND((SELECT MAX(rev) FROM weekly_rev) / 1e6 , 4)    AS max_weekly_revenue_millions,
  ROUND((SELECT MAX(rev) FROM monthly_rev) / 1e6 , 4)   AS max_monthly_revenue_millions;