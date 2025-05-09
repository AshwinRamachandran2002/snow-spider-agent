WITH base AS (  -- every product hit, Jan‑Jun 2017
  SELECT
    trafficSource.source                                       AS traffic_source,
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)                        AS day,
    FORMAT_DATE('%G-W%V', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS iso_week,
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX))  AS month,
    p.productRevenue / 1e6                                     AS revenue_million   -- convert to millions
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS h,
        UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
),

totals AS (  -- total revenue per traffic source
  SELECT
    traffic_source,
    SUM(revenue_million) AS total_rev
  FROM base
  GROUP BY traffic_source
),

top_src AS (  -- highest‑revenue source
  SELECT traffic_source
  FROM totals
  ORDER BY total_rev DESC
  LIMIT 1
),

filtered AS (  -- rows for the top source
  SELECT *
  FROM   base
  WHERE  traffic_source = (SELECT traffic_source FROM top_src)
)

SELECT
  ts.traffic_source AS traffic_source,
  ROUND(t.total_rev, 4) AS total_product_revenue_millions,
  -- maximum daily revenue
  ROUND((
    SELECT MAX(day_rev)
    FROM (SELECT SUM(revenue_million) AS day_rev
          FROM filtered
          GROUP BY day)
  ), 4) AS max_daily_product_revenue_millions,
  -- maximum weekly revenue
  ROUND((
    SELECT MAX(week_rev)
    FROM (SELECT SUM(revenue_million) AS week_rev
          FROM filtered
          GROUP BY iso_week)
  ), 4) AS max_weekly_product_revenue_millions,
  -- maximum monthly revenue
  ROUND((
    SELECT MAX(month_rev)
    FROM (SELECT SUM(revenue_million) AS month_rev
          FROM filtered
          GROUP BY month)
  ), 4) AS max_monthly_product_revenue_millions
FROM top_src ts
JOIN totals t USING (traffic_source)