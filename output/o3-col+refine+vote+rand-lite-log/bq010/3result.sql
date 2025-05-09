-- Top-selling product (by revenue) among customers who purchased
-- “YouTube Men’s Vintage Henley” in July-2017, excluding the Henley itself
WITH henley_buyers AS (
  SELECT DISTINCT fullVisitorId
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
        UNNEST(hits)     AS hit,
        UNNEST(hit.product) AS product
  WHERE product.productRevenue IS NOT NULL
    AND LOWER(product.v2ProductName) LIKE '%youtube%vintage%henley%'
),

other_purchases AS (
  SELECT
    product.v2ProductName                     AS product_name,
    SUM(product.productRevenue)/1e6           AS total_revenue_usd
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
        UNNEST(hits)     AS hit,
        UNNEST(hit.product) AS product
  WHERE product.productRevenue IS NOT NULL
    AND fullVisitorId IN (SELECT fullVisitorId FROM henley_buyers)
    AND LOWER(product.v2ProductName) NOT LIKE '%youtube%vintage%henley%'
  GROUP BY product_name
)

SELECT product_name,
       total_revenue_usd
FROM   other_purchases
ORDER BY total_revenue_usd DESC
LIMIT 1;