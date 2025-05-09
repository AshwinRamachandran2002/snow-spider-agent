-- Top-selling product (other than the Henley itself) bought by customers
-- who purchased a “YouTube Men’s Vintage Henley” in July-2017

WITH july_purchases AS (
  -- every purchased product in July-2017
  SELECT
    fullVisitorId,
    LOWER(p.v2ProductName) AS product_lc,
    p.v2ProductName        AS product_name,
    IFNULL(p.productQuantity ,1) AS qty
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits)   AS h,
    UNNEST(h.product) AS p
  WHERE
    p.productRevenue IS NOT NULL            -- real sales only
),
henley_customers AS (
  -- customers who bought the YouTube Vintage Henley
  SELECT DISTINCT fullVisitorId
  FROM july_purchases
  WHERE product_lc LIKE '%youtube%'
    AND product_lc LIKE '%vintage%'
    AND product_lc LIKE '%henley%'
)

SELECT
  product_name        AS top_selling_product,
  SUM(qty)            AS total_units_sold
FROM
  july_purchases
WHERE
  fullVisitorId IN (SELECT fullVisitorId FROM henley_customers)   -- only Henley buyers
  AND product_lc NOT LIKE '%vintage%henley%'                      -- exclude any Henley
GROUP BY top_selling_product
ORDER BY total_units_sold DESC
LIMIT 1;