/*  Highest‑quantity non‑“YouTube” product bought in July‑2017
    by visitors who purchased at least one “YouTube” product     */
WITH july_products AS (
  SELECT
    fullVisitorId,
    p.v2ProductName  AS product_name,
    p.productQuantity AS qty
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits)        AS h,
    UNNEST(h.product)   AS p
  WHERE
    p.productQuantity IS NOT NULL
    AND p.productQuantity > 0
    AND p.v2ProductName IS NOT NULL
),

-- Visitors who bought at least one product whose name contains “YouTube”
youtube_buyers AS (
  SELECT DISTINCT fullVisitorId
  FROM july_products
  WHERE LOWER(product_name) LIKE '%youtube%'
),

-- Quantities for NON‑“YouTube” products bought by those visitors
other_products AS (
  SELECT
    product_name,
    SUM(qty) AS total_qty
  FROM july_products
  WHERE fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
    AND LOWER(product_name) NOT LIKE '%youtube%'
  GROUP BY product_name
)

SELECT
  product_name,
  total_qty
FROM other_products
ORDER BY total_qty DESC
LIMIT 1;