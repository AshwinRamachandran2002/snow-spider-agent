WITH base AS (
  -- product‑level revenue per source and day (first half of 2017)
  SELECT
    trafficSource.source                                        AS source,
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)                         AS day,
    SUM(p.productRevenue) / 1e6                                 AS revenue_millions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)    AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
    AND p.productRevenue > 0
  GROUP BY source, day
),
source_totals AS (
  -- total revenue per source across the whole period
  SELECT
    source,
    SUM(revenue_millions) AS total_revenue_millions
  FROM base
  GROUP BY source
),
top_source AS (
  -- the traffic source with the highest total product revenue
  SELECT *
  FROM source_totals
  ORDER BY total_revenue_millions DESC
  LIMIT 1
),
daily AS (
  -- day‑level revenue for the top source
  SELECT b.source, b.day, b.revenue_millions
  FROM base AS b
  JOIN top_source AS t USING (source)
),
weekly AS (
  -- ISO‑week‑level revenue for the top source
  SELECT
    source,
    FORMAT_DATE('%G-W%V', day)           AS iso_week,
    SUM(revenue_millions)                AS weekly_revenue_millions
  FROM daily
  GROUP BY source, iso_week
),
monthly AS (
  -- month‑level revenue for the top source
  SELECT
    source,
    FORMAT_DATE('%Y%m', day)             AS month_yyyymm,
    SUM(revenue_millions)                AS monthly_revenue_millions
  FROM daily
  GROUP BY source, month_yyyymm
)
SELECT
  t.source                                                    AS traffic_source,
  ROUND(t.total_revenue_millions       ,4)                    AS total_product_revenue_millions,
  ROUND((SELECT MAX(revenue_millions)           FROM daily)  ,4) AS max_daily_product_revenue_millions,
  ROUND((SELECT MAX(weekly_revenue_millions)    FROM weekly) ,4) AS max_weekly_product_revenue_millions,
  ROUND((SELECT MAX(monthly_revenue_millions)   FROM monthly),4) AS max_monthly_product_revenue_millions
FROM top_source AS t;