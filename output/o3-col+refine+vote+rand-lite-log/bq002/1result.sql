WITH base AS (
  -- revenue per traffic-source per calendar day
  SELECT
    trafficSource.source                                    AS source ,
    PARSE_DATE('%Y%m%d', date)                              AS calendar_day ,
    EXTRACT(ISOYEAR FROM PARSE_DATE('%Y%m%d', date))        AS iso_year ,
    EXTRACT(ISOWEEK FROM PARSE_DATE('%Y%m%d', date))        AS iso_week ,
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))        AS year_month ,
    SUM(p.productRevenue)                                   AS revenue_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
       UNNEST(hits)      AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0630'             -- 2017-H1
    AND p.productRevenue IS NOT NULL
  GROUP BY source, calendar_day, iso_year, iso_week, year_month
),
-- traffic-source with the largest total revenue in H1-2017
top_source AS (
  SELECT source
  FROM   base
  GROUP  BY source
  ORDER  BY SUM(revenue_micro) DESC
  LIMIT  1
),
-- maximum DAILY revenue (top source only)
daily_max AS (
  SELECT MAX(revenue_micro) AS max_daily_micro
  FROM   base
  WHERE  source = (SELECT source FROM top_source)
),
-- maximum WEEKLY revenue (top source only)
weekly_max AS (
  SELECT MAX(weekly_micro) AS max_weekly_micro
  FROM (
        SELECT
          source,
          iso_year,
          iso_week,
          SUM(revenue_micro) AS weekly_micro
        FROM base
        GROUP BY source, iso_year, iso_week
       )
  WHERE source = (SELECT source FROM top_source)
),
-- maximum MONTHLY revenue (top source only)
monthly_max AS (
  SELECT MAX(monthly_micro) AS max_monthly_micro
  FROM (
        SELECT
          source,
          year_month,
          SUM(revenue_micro) AS monthly_micro
        FROM base
        GROUP BY source, year_month
       )
  WHERE source = (SELECT source FROM top_source)
)

SELECT
  (SELECT source           FROM top_source)                 AS top_traffic_source ,
  (SELECT max_daily_micro   FROM daily_max)   / 1e12        AS max_daily_revenue_millions ,
  (SELECT max_weekly_micro  FROM weekly_max)  / 1e12        AS max_weekly_revenue_millions ,
  (SELECT max_monthly_micro FROM monthly_max) / 1e12        AS max_monthly_revenue_millions ;