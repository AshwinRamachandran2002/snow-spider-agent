WITH base AS (
  -- all purchased products (quantity>0) in July‑2017
  SELECT
    s.fullVisitorId,
    p.v2ProductName AS product_name,
    p.productQuantity        AS quantity
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits)   AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE p.productQuantity IS NOT NULL
    AND p.productQuantity > 0
),
youtube_buyers AS (
  -- visitors who bought any product whose name contains 'YouTube'
  SELECT DISTINCT fullVisitorId
  FROM base
  WHERE LOWER(product_name) LIKE '%youtube%'
),
other_products AS (
  -- purchases of non‑YouTube products made by those visitors
  SELECT
    product_name,
    SUM(quantity) AS total_qty
  FROM base
  WHERE fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
    AND LOWER(product_name) NOT LIKE '%youtube%'
  GROUP BY product_name
)
SELECT product_name, total_qty
FROM other_products
ORDER BY total_qty DESC
LIMIT 1;