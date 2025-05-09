-- Highest-grossing traffic-source in H1-2017 and its max daily, weekly, monthly revenues
WITH  all_sessions AS (
  SELECT
    trafficSource.source                      AS source,
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)       AS sess_date,
    IFNULL(p.productRevenue,0)                AS prod_rev
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits)   AS h,
        UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
),

-- total revenue per source in the period
src_totals AS (
  SELECT source, SUM(prod_rev) AS total_rev
  FROM   all_sessions
  GROUP  BY source
  ORDER  BY total_rev DESC
  LIMIT  1                        -- pick the top-performing source
),

-- keep only rows that belong to that top source
top_src_data AS (
  SELECT a.*
  FROM   all_sessions  AS a
  JOIN   src_totals    AS t
  ON     a.source = t.source
),

-- aggregate by different time grains
daily_rev AS (
  SELECT sess_date                          AS grp,
         SUM(prod_rev) / 1e6 AS revenue_m
  FROM   top_src_data
  GROUP  BY sess_date
),
weekly_rev AS (
  SELECT FORMAT_DATE('%G-W%V', sess_date)   AS grp,
         SUM(prod_rev) / 1e6 AS revenue_m
  FROM   top_src_data
  GROUP  BY grp
),
monthly_rev AS (
  SELECT FORMAT_DATE('%Y-%m', sess_date)    AS grp,
         SUM(prod_rev) / 1e6 AS revenue_m
  FROM   top_src_data
  GROUP  BY grp
)

SELECT
  (SELECT source FROM src_totals)                    AS top_traffic_source,
  (SELECT MAX(revenue_m) FROM daily_rev)   AS max_daily_revenue_m,
  (SELECT MAX(revenue_m) FROM weekly_rev)  AS max_weekly_revenue_m,
  (SELECT MAX(revenue_m) FROM monthly_rev) AS max_monthly_revenue_m;