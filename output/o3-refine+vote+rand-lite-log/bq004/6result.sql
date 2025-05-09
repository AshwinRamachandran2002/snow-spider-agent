-- Highest‑quantity non‑“YouTube” product bought (in July‑2017) by visitors
-- who purchased at least one “YouTube”‑related product
WITH purchases AS (
  SELECT
    s.fullVisitorId,
    p.v2ProductName                       AS product_name,
    LOWER(p.v2ProductName)                AS product_name_lower,
    p.productQuantity                     AS qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits)   AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE h.transaction.transactionId IS NOT NULL        -- purchase hits
    AND p.productQuantity IS NOT NULL                  -- has quantity
),

youtube_buyers AS (
  SELECT DISTINCT fullVisitorId
  FROM purchases
  WHERE product_name_lower LIKE '%youtube%'             -- bought YouTube product
)

SELECT
  product_name,
  SUM(qty) AS total_quantity
FROM purchases
WHERE fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers) -- only those buyers
  AND product_name_lower NOT LIKE '%youtube%'                     -- exclude YouTube products
GROUP BY product_name
ORDER BY total_quantity DESC
LIMIT 1;