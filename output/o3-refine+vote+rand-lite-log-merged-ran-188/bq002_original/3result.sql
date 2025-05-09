WITH base AS (
  -- every product‑revenue record for the 1st half of 2017
  SELECT
    trafficSource.source                                    AS source,
    PARSE_DATE('%Y%m%d', date)                              AS session_date,
    SAFE_DIVIDE(COALESCE(p.productRevenue,0),1e6)           AS product_rev_million   -- convert to millions
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits)   AS h
  LEFT JOIN UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
),

-- total product revenue by traffic source
source_totals AS (
  SELECT source,
         SUM(product_rev_million) AS total_rev_million
  FROM   base
  GROUP  BY source
  ORDER  BY total_rev_million DESC
  LIMIT  1                         -- keep only the top‑performing source
),

-- daily, weekly and monthly revenue for that top source
daily_rev AS (
  SELECT session_date,
         SUM(product_rev_million) AS rev
  FROM   base
  WHERE  source = (SELECT source FROM source_totals)
  GROUP  BY session_date
),
weekly_rev AS (
  SELECT DATE_TRUNC(session_date, WEEK(MONDAY)) AS week_start,
         SUM(product_rev_million)               AS rev
  FROM   base
  WHERE  source = (SELECT source FROM source_totals)
  GROUP  BY week_start
),
monthly_rev AS (
  SELECT DATE_TRUNC(session_date, MONTH) AS month_start,
         SUM(product_rev_million)        AS rev
  FROM   base
  WHERE  source = (SELECT source FROM source_totals)
  GROUP  BY month_start
)

-- final answer
SELECT
  (SELECT source FROM source_totals)               AS top_traffic_source,
  ROUND((SELECT MAX(rev) FROM daily_rev),   4)     AS max_daily_revenue_million,
  ROUND((SELECT MAX(rev) FROM weekly_rev),  4)     AS max_weekly_revenue_million,
  ROUND((SELECT MAX(rev) FROM monthly_rev), 4)     AS max_monthly_revenue_million;