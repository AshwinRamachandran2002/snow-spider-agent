WITH product_revenue_per_day AS (
  -- Aggregate product‑level revenue per traffic source and calendar day
  SELECT
    IFNULL(trafficSource.source, '(unknown)')              AS source,
    _TABLE_SUFFIX                                          AS yyyymmdd,
    SUM(product.productRevenue)                            AS revenue_micro   -- micro‑currency units
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits)        AS hit,
    UNNEST(hit.product) AS product
  WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'    -- first half of 2017
    AND product.productRevenue IS NOT NULL
  GROUP BY
    source, yyyymmdd
),

-- Total (Jan‑Jun 2017) revenue by source; keep the top performer
source_totals AS (
  SELECT
    source,
    SUM(revenue_micro) AS total_micro
  FROM product_revenue_per_day
  GROUP BY source
  ORDER BY total_micro DESC
  LIMIT 1
),

-- Daily revenue for the top source
top_daily AS (
  SELECT
    yyyymmdd,
    revenue_micro
  FROM product_revenue_per_day
  JOIN source_totals USING (source)
),

-- Weekly revenue (ISO week, Monday start) for the top source
top_weekly AS (
  SELECT
    FORMAT_DATE('%G-W%V', DATE_TRUNC(PARSE_DATE('%Y%m%d', yyyymmdd), WEEK(MONDAY))) AS iso_week,
    SUM(revenue_micro) AS revenue_micro
  FROM top_daily
  GROUP BY iso_week
),

-- Monthly revenue for the top source
top_monthly AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE_TRUNC(PARSE_DATE('%Y%m%d', yyyymmdd), MONTH)) AS month,
    SUM(revenue_micro) AS revenue_micro
  FROM top_daily
  GROUP BY month
)

-- Final answer
SELECT
  st.source                                                         AS top_traffic_source,
  ROUND(st.total_micro                  / 1e6, 4) AS total_revenue_millions,
  ROUND((SELECT MAX(revenue_micro) FROM top_daily)   / 1e6, 4) AS max_daily_revenue_millions,
  ROUND((SELECT MAX(revenue_micro) FROM top_weekly)  / 1e6, 4) AS max_weekly_revenue_millions,
  ROUND((SELECT MAX(revenue_micro) FROM top_monthly) / 1e6, 4) AS max_monthly_revenue_millions
FROM source_totals st;