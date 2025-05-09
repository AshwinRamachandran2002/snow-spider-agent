/* Top‑selling product (by units) among customers who bought
   “YouTube Men’s Vintage Henley” during July 2017, excluding the Henley itself */

WITH july_products AS (   -- every product actually purchased (revenue > 0) in July‑2017
  SELECT
    s.fullVisitorId,
    p.v2ProductName                     AS product_name,
    IFNULL(p.productQuantity, 1)        AS qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits)  AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE p.productRevenue IS NOT NULL AND p.productRevenue > 0
        AND p.v2ProductName IS NOT NULL
),

henley_buyers AS (        -- visitors who purchased the Henley
  SELECT DISTINCT fullVisitorId
  FROM july_products
  WHERE LOWER(product_name) LIKE '%henley%'
),

co_purchases AS (        -- other items those visitors purchased
  SELECT
    jp.product_name,
    jp.qty
  FROM july_products AS jp
  JOIN henley_buyers USING (fullVisitorId)
  WHERE NOT LOWER(jp.product_name) LIKE '%henley%'
)

SELECT
  product_name,
  SUM(qty) AS total_units_sold
FROM co_purchases
GROUP BY product_name
ORDER BY total_units_sold DESC
LIMIT 1;