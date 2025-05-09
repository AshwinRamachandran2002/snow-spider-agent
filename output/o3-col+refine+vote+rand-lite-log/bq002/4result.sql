WITH revenue_by_source AS (                -- total revenue per source
  SELECT
    trafficSource.source              AS src,
    SUM(p.productRevenue)             AS total_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)    AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND p.productRevenue IS NOT NULL
  GROUP BY src
),
top_source AS (                            -- #1 source
  SELECT src, total_rev
  FROM revenue_by_source
  ORDER BY total_rev DESC
  LIMIT 1
),
daily AS (                                 -- daily revenue for that source
  SELECT
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS calendar_date,
    SUM(p.productRevenue)               AS day_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)    AS h,
       UNNEST(h.product) AS p,
       top_source
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND trafficSource.source = top_source.src
    AND p.productRevenue IS NOT NULL
  GROUP BY calendar_date
),
weekly AS (                                -- weekly revenue for that source
  SELECT
    EXTRACT(ISOYEAR FROM calendar_date) AS iso_year,
    EXTRACT(ISOWEEK FROM calendar_date) AS iso_week,
    SUM(productRevenue)                 AS week_rev
  FROM (
    SELECT
      PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS calendar_date,
      p.productRevenue                    AS productRevenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
         UNNEST(hits)    AS h,
         UNNEST(h.product) AS p,
         top_source
    WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
      AND trafficSource.source = top_source.src
      AND p.productRevenue IS NOT NULL
  )
  GROUP BY iso_year, iso_week
),
monthly AS (                               -- monthly revenue for that source
  SELECT
    FORMAT_DATE('%Y-%m', calendar_date) AS month_id,
    SUM(productRevenue)                 AS month_rev
  FROM (
    SELECT
      PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS calendar_date,
      p.productRevenue                    AS productRevenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
         UNNEST(hits)    AS h,
         UNNEST(h.product) AS p,
         top_source
    WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
      AND trafficSource.source = top_source.src
      AND p.productRevenue IS NOT NULL
  )
  GROUP BY month_id
)
SELECT
  top_source.src                   AS top_traffic_source,
  top_source.total_rev  / 1e6      AS total_revenue_million,
  (SELECT MAX(day_rev)  FROM daily)   / 1e6 AS max_daily_revenue_million,
  (SELECT MAX(week_rev) FROM weekly)  / 1e6 AS max_weekly_revenue_million,
  (SELECT MAX(month_rev) FROM monthly)/ 1e6 AS max_monthly_revenue_million
FROM top_source;