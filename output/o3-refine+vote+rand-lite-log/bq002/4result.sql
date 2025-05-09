/*  Maximum daily, weekly, and monthly product revenue (millions)
    for the trafficSource.source that drove the greatest total
    product revenue during 1 Jan 2017 – 30 Jun 2017. */

WITH sessions AS (
  SELECT
    trafficSource.source                        AS source,
    PARSE_DATE('%Y%m%d', `date`)               AS session_date,
    prod.productRevenue                        AS product_revenue_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  CROSS JOIN UNNEST(hits)           AS hit
  CROSS JOIN UNNEST(hit.product)    AS prod
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND prod.productRevenue IS NOT NULL
),

source_totals AS (
  SELECT
    source,
    SUM(product_revenue_micro) / 1e6 AS total_revenue
  FROM sessions
  GROUP BY source
),

top_source AS (
  SELECT source
  FROM source_totals
  ORDER BY total_revenue DESC
  LIMIT 1
),

top_sessions AS (
  SELECT
    s.session_date,
    s.product_revenue_micro
  FROM sessions AS s
  JOIN top_source AS t
  ON s.source = t.source
),

daily_rev AS (
  SELECT
    session_date,
    SUM(product_revenue_micro) / 1e6 AS revenue
  FROM top_sessions
  GROUP BY session_date
),

weekly_rev AS (
  SELECT
    DATE_TRUNC(session_date, WEEK(MONDAY))     AS week_start,
    SUM(product_revenue_micro) / 1e6           AS revenue
  FROM top_sessions
  GROUP BY week_start
),

monthly_rev AS (
  SELECT
    DATE_TRUNC(session_date, MONTH)            AS month_start,
    SUM(product_revenue_micro) / 1e6           AS revenue
  FROM top_sessions
  GROUP BY month_start
)

SELECT
  (SELECT source FROM top_source)               AS traffic_source,
  (SELECT MAX(revenue) FROM daily_rev)   AS max_daily_revenue_million,
  (SELECT MAX(revenue) FROM weekly_rev)  AS max_weekly_revenue_million,
  (SELECT MAX(revenue) FROM monthly_rev) AS max_monthly_revenue_million;