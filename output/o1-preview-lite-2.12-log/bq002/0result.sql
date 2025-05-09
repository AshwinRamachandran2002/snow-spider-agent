WITH top_source AS (
  SELECT
    trafficSource.source AS Traffic_Source,
    SUM(product.productRevenue) / 1e6 AS Total_Product_Revenue_in_millions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit,
    UNNEST(hit.product) AS product
  WHERE PARSE_DATE('%Y%m%d', date) BETWEEN DATE('2017-01-01') AND DATE('2017-06-30')
    AND product.productRevenue IS NOT NULL
  GROUP BY Traffic_Source
  ORDER BY Total_Product_Revenue_in_millions DESC
  LIMIT 1
),

daily_revenue AS (
  SELECT
    PARSE_DATE('%Y%m%d', date) AS session_date,
    SUM(product.productRevenue) / 1e6 AS daily_revenue_millions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit,
    UNNEST(hit.product) AS product,
    top_source
  WHERE PARSE_DATE('%Y%m%d', date) BETWEEN DATE('2017-01-01') AND DATE('2017-06-30')
    AND product.productRevenue IS NOT NULL
    AND trafficSource.source = top_source.Traffic_Source
  GROUP BY session_date
),

weekly_revenue AS (
  SELECT
    FORMAT_DATE('%Y-%U', session_date) AS session_week,
    SUM(daily_revenue_millions) AS weekly_revenue_millions
  FROM daily_revenue
  GROUP BY session_week
),

monthly_revenue AS (
  SELECT
    FORMAT_DATE('%Y-%m', session_date) AS session_month,
    SUM(daily_revenue_millions) AS monthly_revenue_millions
  FROM daily_revenue
  GROUP BY session_month
)

SELECT
  top_source.Traffic_Source,
  top_source.Total_Product_Revenue_in_millions,
  (SELECT MAX(daily_revenue_millions) FROM daily_revenue) AS Maximum_Daily_Revenue_in_millions,
  (SELECT MAX(weekly_revenue_millions) FROM weekly_revenue) AS Maximum_Weekly_Revenue_in_millions,
  (SELECT MAX(monthly_revenue_millions) FROM monthly_revenue) AS Maximum_Monthly_Revenue_in_millions
FROM top_source;