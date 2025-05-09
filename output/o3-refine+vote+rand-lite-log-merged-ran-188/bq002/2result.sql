WITH all_revenue AS (
  -- every product-level revenue record in H1-2017
  SELECT
    trafficSource.source                 AS source,
    PARSE_DATE('%Y%m%d', date)           AS cal_date,
    p.productRevenue                     AS revenue_micro
  FROM   `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
         UNNEST(hits)      AS h,
         UNNEST(h.product) AS p
  WHERE  _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND  p.productRevenue IS NOT NULL
),
-- source with the greatest total revenue
top_source AS (
  SELECT source
  FROM   all_revenue
  GROUP  BY source
  ORDER  BY SUM(revenue_micro) DESC
  LIMIT  1
),
-- daily totals for that source
daily AS (
  SELECT
    cal_date,
    SUM(revenue_micro) / 1e6 AS daily_rev
  FROM   all_revenue
  JOIN   top_source USING (source)
  GROUP  BY cal_date
),
-- ISO-weekly totals for that source
weekly AS (
  SELECT
    FORMAT('%d-W%02d',
           EXTRACT(ISOYEAR  FROM cal_date),
           EXTRACT(ISOWEEK FROM cal_date)) AS iso_week,
    SUM(revenue_micro) / 1e6               AS weekly_rev
  FROM   all_revenue
  JOIN   top_source USING (source)
  GROUP  BY iso_week
),
-- calendar-month totals for that source
monthly AS (
  SELECT
    FORMAT('%d-%02d',
           EXTRACT(YEAR  FROM cal_date),
           EXTRACT(MONTH FROM cal_date))   AS yr_month,
    SUM(revenue_micro) / 1e6               AS monthly_rev
  FROM   all_revenue
  JOIN   top_source USING (source)
  GROUP  BY yr_month
)

SELECT
  (SELECT source           FROM top_source) AS top_traffic_source,
  (SELECT MAX(daily_rev)  FROM daily)       AS max_daily_revenue_million,
  (SELECT MAX(weekly_rev) FROM weekly)      AS max_weekly_revenue_million,
  (SELECT MAX(monthly_rev)FROM monthly)     AS max_monthly_revenue_million;