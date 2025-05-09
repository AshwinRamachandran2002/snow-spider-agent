-- Non‑YouTube product with the highest quantity bought in July‑2017
-- by visitors who purchased at least one YouTube‑related product
WITH july_products AS (          -- all products actually purchased in July‑2017
  SELECT
    s.fullVisitorId,
    p.v2ProductName              AS product_name,
    COALESCE(p.productQuantity,1) AS qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits)  AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE h.eCommerceAction.action_type = '6'     -- 6 = completed purchase
),

youtube_buyers AS (              -- visitors who bought any “YouTube” product
  SELECT DISTINCT fullVisitorId
  FROM july_products
  WHERE LOWER(product_name) LIKE '%youtube%'
),

other_products AS (              -- purchases of non‑YouTube products by those visitors
  SELECT
    product_name,
    SUM(qty) AS total_qty
  FROM july_products
  WHERE fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
    AND LOWER(product_name) NOT LIKE '%youtube%'
    AND product_name IS NOT NULL
  GROUP BY product_name
)

SELECT product_name
FROM other_products
ORDER BY total_qty DESC, product_name
LIMIT 1;