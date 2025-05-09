/*  Top–performing traffic source in H1-2017 and its peak daily, weekly, and monthly
    product-revenue values (amounts already converted from micro-units to “millions”) */

WITH base AS (   -- every product-revenue hit in H1-2017
  SELECT
    trafficSource.source                         AS source,
    PARSE_DATE('%Y%m%d', date)                  AS dt,
    p.productRevenue / 1e6                      AS rev_m       -- convert to millions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)    AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
),

-- identify the single source with the highest total revenue
top_source AS (
  SELECT source
  FROM base
  GROUP BY source
  ORDER BY SUM(rev_m) DESC
  LIMIT 1
),

-- aggregates for that source only
daily   AS (SELECT dt,
                   SUM(rev_m) AS daily_rev_m
            FROM base, top_source
            WHERE base.source = top_source.source
            GROUP BY dt),

weekly  AS (SELECT FORMAT_DATE('%G-%V', dt) AS iso_week,
                   SUM(rev_m)               AS weekly_rev_m
            FROM base, top_source
            WHERE base.source = top_source.source
            GROUP BY iso_week),

monthly AS (SELECT FORMAT_DATE('%Y-%m', dt) AS ym,
                   SUM(rev_m)               AS monthly_rev_m
            FROM base, top_source
            WHERE base.source = top_source.source
            GROUP BY ym)

SELECT
  ts.source                                       AS traffic_source,
  ROUND(SUM(b.rev_m),6)                           AS total_revenue_m,
  ROUND((SELECT MAX(daily_rev_m)   FROM daily),6) AS max_daily_revenue_m,
  ROUND((SELECT MAX(weekly_rev_m)  FROM weekly),6) AS max_weekly_revenue_m,
  ROUND((SELECT MAX(monthly_rev_m) FROM monthly),6) AS max_monthly_revenue_m
FROM base b
JOIN top_source ts
ON b.source = ts.source
GROUP BY ts.source;