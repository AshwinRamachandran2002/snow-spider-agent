WITH top_traffic_source AS (
  SELECT
    `trafficSource`.`source` AS source,
    `trafficSource`.`medium` AS medium,
    SUM(product.`productRevenue`) AS total_product_revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(`hits`) AS hit,
    UNNEST(hit.`product`) AS product
  WHERE
    product.`productRevenue` IS NOT NULL
    AND PARSE_DATE('%Y%m%d', `date`) BETWEEN DATE('2017-01-01') AND DATE('2017-06-30')
  GROUP BY
    source, medium
  ORDER BY
    total_product_revenue DESC
  LIMIT 1
),
daily_revenues AS (
  SELECT
    PARSE_DATE('%Y%m%d', `date`) AS date,
    SUM(product.`productRevenue`) AS daily_revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(`hits`) AS hit,
    UNNEST(hit.`product`) AS product,
    top_traffic_source
  WHERE
    product.`productRevenue` IS NOT NULL
    AND `trafficSource`.`source` = top_traffic_source.source
    AND `trafficSource`.`medium` = top_traffic_source.medium
    AND PARSE_DATE('%Y%m%d', `date`) BETWEEN DATE('2017-01-01') AND DATE('2017-06-30')
  GROUP BY
    date
),
weekly_revenues AS (
  SELECT
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(WEEK FROM date) AS week,
    SUM(daily_revenue) AS weekly_revenue
  FROM
    daily_revenues
  GROUP BY
    year, week
),
monthly_revenues AS (
  SELECT
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month,
    SUM(daily_revenue) AS monthly_revenue
  FROM
    daily_revenues
  GROUP BY
    year, month
),
max_revenues AS (
  SELECT
    'Daily' AS Time_Frame,
    MAX(daily_revenue)/1000000 AS Maximum_Product_Revenue_In_Millions
  FROM
    daily_revenues
  UNION ALL
  SELECT
    'Weekly',
    MAX(weekly_revenue)/1000000
  FROM
    weekly_revenues
  UNION ALL
  SELECT
    'Monthly',
    MAX(monthly_revenue)/1000000
  FROM
    monthly_revenues
)
SELECT
  Time_Frame,
  ROUND(Maximum_Product_Revenue_In_Millions, 4) AS Maximum_Product_Revenue_In_Millions
FROM
  max_revenues
ORDER BY
  CASE 
    WHEN Time_Frame = 'Monthly' THEN 1
    WHEN Time_Frame = 'Weekly' THEN 2
    WHEN Time_Frame = 'Daily' THEN 3
    ELSE 4
  END;