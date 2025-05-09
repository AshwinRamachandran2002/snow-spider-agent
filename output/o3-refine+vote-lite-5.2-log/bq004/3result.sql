WITH purchased_products AS (
  SELECT
    s.fullVisitorId,
    COALESCE(p.productQuantity, 1) AS qty,
    p.v2ProductName                       AS product_name,
    LOWER(p.v2ProductName)                AS product_name_lower
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits)    AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE p.v2ProductName IS NOT NULL
        -- keep rows that represent a purchase (quantity or revenue recorded)
        AND (p.productQuantity IS NOT NULL
             OR p.productRevenue IS NOT NULL
             OR p.localProductRevenue IS NOT NULL)
),
youtube_buyers AS (                        -- visitors who bought any YouTube‑related product
  SELECT DISTINCT fullVisitorId
  FROM purchased_products
  WHERE product_name_lower LIKE '%youtube%'
),
non_youtube_sales AS (                     -- their other (non‑YouTube) purchases
  SELECT
    product_name,
    SUM(qty) AS total_qty
  FROM purchased_products
  WHERE fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
    AND product_name_lower NOT LIKE '%youtube%'
  GROUP BY product_name
)
SELECT product_name, total_qty
FROM non_youtube_sales
ORDER BY total_qty DESC
LIMIT 1;