-- Top-selling “other” product (by revenue) among July-2017 customers
-- who purchased “YouTube Men’s Vintage Henley” (exclude all Henley items)

WITH henley_buyers AS (
  -- visitors who bought the target Henley during July-2017
  SELECT DISTINCT fullVisitorId
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
        UNNEST(hits)    AS h,
        UNNEST(h.product) AS p
  WHERE LOWER(p.v2ProductName) LIKE '%youtube%vintage%henley%'   -- target item
    AND p.productRevenue IS NOT NULL
),

other_products AS (
  -- revenue of all *other* products those visitors bought in July-2017
  SELECT
    p.v2ProductName                         AS product_name,
    SUM(p.productRevenue) / 1e6            AS total_revenue_usd
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
        UNNEST(hits)    AS h,
        UNNEST(h.product) AS p
  WHERE fullVisitorId IN (SELECT fullVisitorId FROM henley_buyers)
    AND LOWER(p.v2ProductName) NOT LIKE '%henley%'               -- exclude Henley
    AND p.productRevenue IS NOT NULL
  GROUP BY product_name
)

SELECT product_name      AS top_product,
       total_revenue_usd
FROM   other_products
ORDER  BY total_revenue_usd DESC
LIMIT  1;