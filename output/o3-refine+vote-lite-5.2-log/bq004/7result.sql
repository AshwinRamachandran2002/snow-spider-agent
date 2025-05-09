WITH july_purchases AS (
  SELECT
    s.fullVisitorId,
    p.v2ProductName AS product_name,
    p.productQuantity AS quantity
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits)  AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE p.productQuantity IS NOT NULL
    AND p.productQuantity > 0                     -- keep only real purchases
),

youtube_buyers AS (                               -- visitors who bought any YouTube item
  SELECT DISTINCT fullVisitorId
  FROM july_purchases
  WHERE LOWER(product_name) LIKE '%youtube%'
),

candidate_products AS (                           -- non‑YouTube products they also bought
  SELECT
    product_name,
    SUM(quantity) AS total_quantity
  FROM july_purchases
  WHERE fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
    AND LOWER(product_name) NOT LIKE '%youtube%'
  GROUP BY product_name
)

SELECT product_name,
       total_quantity
FROM candidate_products
ORDER BY total_quantity DESC
LIMIT 1;