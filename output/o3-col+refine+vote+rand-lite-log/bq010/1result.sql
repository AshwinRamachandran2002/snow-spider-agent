/* Top-selling product (by units) bought in July-2017 by visitors who
   purchased “YouTube Men’s Vintage Henley”, excluding that Henley itself */
WITH henley_buyers AS (
  SELECT DISTINCT fullVisitorId
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits)     AS h,
        UNNEST(h.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
    AND LOWER(product.v2ProductName) LIKE '%youtube%vintage%henley%'
    AND product.productRevenue IS NOT NULL            -- ensured it was purchased
),
buyer_products AS (
  SELECT
    product.v2ProductName                       AS product_name,
    IFNULL(product.productQuantity,1)           AS qty
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits)     AS h,
        UNNEST(h.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
    AND fullVisitorId IN (SELECT fullVisitorId FROM henley_buyers)
    AND product.productRevenue IS NOT NULL        -- only purchased items
    AND LOWER(product.v2ProductName) NOT LIKE '%youtube%vintage%henley%'  -- exclude Henley itself
)
SELECT
  product_name,
  SUM(qty) AS total_units
FROM buyer_products
GROUP BY product_name
ORDER BY total_units DESC
LIMIT 1;