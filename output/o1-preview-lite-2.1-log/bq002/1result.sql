WITH top_traffic_source AS (
  SELECT
    CONCAT(trafficSource.source, '/', trafficSource.medium) AS traffic_source
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND product.productRevenue IS NOT NULL
  GROUP BY
    traffic_source
  ORDER BY
    SUM(product.productRevenue) DESC
  LIMIT 1
),

monthly_revenues AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', sessions.date)) AS month,
    SUM(product.productRevenue) AS monthly_revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS sessions
    CROSS JOIN UNNEST(sessions.hits) AS hits
    CROSS JOIN UNNEST(hits.product) AS product,
    top_traffic_source
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND product.productRevenue IS NOT NULL
    AND CONCAT(sessions.trafficSource.source, '/', sessions.trafficSource.medium) = top_traffic_source.traffic_source
  GROUP BY
    month
),

weekly_revenues AS (
  SELECT
    EXTRACT(WEEK FROM PARSE_DATE('%Y%m%d', sessions.date)) AS week,
    SUM(product.productRevenue) AS weekly_revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS sessions
    CROSS JOIN UNNEST(sessions.hits) AS hits
    CROSS JOIN UNNEST(hits.product) AS product,
    top_traffic_source
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND product.productRevenue IS NOT NULL
    AND CONCAT(sessions.trafficSource.source, '/', sessions.trafficSource.medium) = top_traffic_source.traffic_source
  GROUP BY
    week
),

daily_revenues AS (
  SELECT
    sessions.date,
    SUM(product.productRevenue) AS daily_revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS sessions
    CROSS JOIN UNNEST(sessions.hits) AS hits
    CROSS JOIN UNNEST(hits.product) AS product,
    top_traffic_source
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND product.productRevenue IS NOT NULL
    AND CONCAT(sessions.trafficSource.source, '/', sessions.trafficSource.medium) = top_traffic_source.traffic_source
  GROUP BY
    sessions.date
)

SELECT 'Monthly' AS Time_Frame,
ROUND(MAX(monthly_revenue) / 1000000, 4) AS Maximum_Product_Revenue_In_Millions
FROM monthly_revenues

UNION ALL

SELECT 'Weekly' AS Time_Frame,
ROUND(MAX(weekly_revenue) / 1000000, 4) AS Maximum_Product_Revenue_In_Millions
FROM weekly_revenues

UNION ALL

SELECT 'Daily' AS Time_Frame,
ROUND(MAX(daily_revenue) / 1000000, 4) AS Maximum_Product_Revenue_In_Millions
FROM daily_revenues

ORDER BY
  Time_Frame;