-- Which non‑‘YouTube’ product was bought the most (by quantity) in July‑2017
-- by visitors who purchased at least one ‘YouTube’‑related product?
WITH july_purchases AS (
  -- All product‑level purchase rows in July‑2017 (action_type = 6)
  SELECT
    fullVisitorId,
    LOWER(p.v2ProductName)   AS product_lc,
    p.v2ProductName          AS product_name,
    p.productQuantity        AS qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
       UNNEST(hits)   AS h,
       UNNEST(h.product) AS p
  WHERE h.eCommerceAction.action_type = '6'          -- completed purchase
    AND p.productQuantity IS NOT NULL
),

visitors_with_youtube AS (
  -- Visitors who bought ANY ‘YouTube’‑related product
  SELECT DISTINCT fullVisitorId
  FROM july_purchases
  WHERE product_lc LIKE '%youtube%'
),

filtered_purchases AS (
  -- Purchases made by those visitors, excluding products that contain ‘YouTube’
  SELECT
    jp.product_name,
    SUM(jp.qty) AS total_qty
  FROM july_purchases jp
  JOIN visitors_with_youtube v
    ON jp.fullVisitorId = v.fullVisitorId
  WHERE jp.product_lc NOT LIKE '%youtube%'
  GROUP BY jp.product_name
)

SELECT
  product_name,
  total_qty
FROM filtered_purchases
ORDER BY total_qty DESC
LIMIT 1;