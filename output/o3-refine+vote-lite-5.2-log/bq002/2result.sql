/*  H1‑2017  |  Product‑level revenue leaders & their peak figures  */

WITH base AS (                       -- every product‑level revenue hit
  SELECT
    trafficSource.source                                   AS source ,
    PARSE_DATE('%Y%m%d', date)                             AS session_date ,
    SAFE_DIVIDE(product.productRevenue , 1e6)              AS revenue_millions
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits)   AS hit ,
    UNNEST(hit.product) AS product
  WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'    -- 1st half‑year
    AND product.productRevenue IS NOT NULL
),

top_source AS (                    -- traffic source with highest total
  SELECT source
  FROM   base
  GROUP BY source
  ORDER BY SUM(revenue_millions) DESC
  LIMIT 1
),

filtered AS (                      -- keep only that top‑performing source
  SELECT b.*
  FROM   base AS b
  JOIN   top_source t USING (source)
),

daily_rev AS (
  SELECT session_date , SUM(revenue_millions) AS rev
  FROM   filtered
  GROUP  BY session_date
),

weekly_rev AS (
  SELECT DATE_TRUNC(session_date , WEEK(MONDAY)) AS week_start ,
         SUM(revenue_millions)                   AS rev
  FROM   filtered
  GROUP  BY week_start
),

monthly_rev AS (
  SELECT DATE_TRUNC(session_date , MONTH)        AS month_start ,
         SUM(revenue_millions)                   AS rev
  FROM   filtered
  GROUP  BY month_start
)

SELECT
  (SELECT source          FROM top_source) AS top_traffic_source ,
  (SELECT MAX(rev) FROM daily_rev  )       AS max_daily_revenue_millions ,
  (SELECT MAX(rev) FROM weekly_rev )       AS max_weekly_revenue_millions ,
  (SELECT MAX(rev) FROM monthly_rev)       AS max_monthly_revenue_millions ;