WITH
  revenue_per_source AS (
    SELECT
      trafficSource.source AS source,
      SUM(IFNULL(product.productRevenue, 0)) / 1e12 AS total_revenue_millions
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
      UNNEST(t.hits) AS hits,
      UNNEST(hits.product) AS product
    WHERE
      _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    GROUP BY
      source
  ),
  top_source AS (
    SELECT
      source,
      total_revenue_millions
    FROM
      revenue_per_source
    ORDER BY
      total_revenue_millions DESC
    LIMIT
      1
  ),
  daily_revenue AS (
    SELECT
      trafficSource.source AS source,
      t.date,
      SUM(IFNULL(product.productRevenue, 0)) / 1e12 AS daily_revenue_millions
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
      UNNEST(t.hits) AS hits,
      UNNEST(hits.product) AS product
    WHERE
      _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    GROUP BY
      source,
      t.date
  ),
  max_daily_revenue AS (
    SELECT
      source,
      MAX(daily_revenue_millions) AS max_daily_revenue_millions
    FROM
      daily_revenue
    WHERE
      source = (SELECT source FROM top_source)
    GROUP BY
      source
  ),
  weekly_revenue AS (
    SELECT
      trafficSource.source AS source,
      FORMAT_DATE('%Y-%V', PARSE_DATE('%Y%m%d', t.date)) AS week,
      SUM(IFNULL(product.productRevenue, 0)) / 1e12 AS weekly_revenue_millions
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
      UNNEST(t.hits) AS hits,
      UNNEST(hits.product) AS product
    WHERE
      _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    GROUP BY
      source,
      week
  ),
  max_weekly_revenue AS (
    SELECT
      source,
      MAX(weekly_revenue_millions) AS max_weekly_revenue_millions
    FROM
      weekly_revenue
    WHERE
      source = (SELECT source FROM top_source)
    GROUP BY
      source
  ),
  monthly_revenue AS (
    SELECT
      trafficSource.source AS source,
      SUBSTR(t.date, 1, 6) AS month,
      SUM(IFNULL(product.productRevenue, 0)) / 1e12 AS monthly_revenue_millions
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
      UNNEST(t.hits) AS hits,
      UNNEST(hits.product) AS product
    WHERE
      _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    GROUP BY
      source,
      month
  ),
  max_monthly_revenue AS (
    SELECT
      source,
      MAX(monthly_revenue_millions) AS max_monthly_revenue_millions
    FROM
      monthly_revenue
    WHERE
      source = (SELECT source FROM top_source)
    GROUP BY
      source
  )
SELECT
  ts.source AS Traffic_Source,
  ROUND(ts.total_revenue_millions, 4) AS Total_Product_Revenue_in_millions,
  ROUND(md.max_daily_revenue_millions, 4) AS Maximum_Daily_Revenue_in_millions,
  ROUND(mw.max_weekly_revenue_millions, 4) AS Maximum_Weekly_Revenue_in_millions,
  ROUND(mm.max_monthly_revenue_millions, 4) AS Maximum_Monthly_Revenue_in_millions
FROM
  top_source ts
  JOIN max_daily_revenue md ON ts.source = md.source
  JOIN max_weekly_revenue mw ON ts.source = mw.source
  JOIN max_monthly_revenue mm ON ts.source = mm.source;