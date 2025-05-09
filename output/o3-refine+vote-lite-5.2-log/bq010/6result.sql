WITH july_products AS (
  -- Item‑level products that were actually purchased in July‑2017
  SELECT
    s.fullVisitorId,
    p.v2ProductName                         AS product_name,
    COALESCE(p.productQuantity, 1) AS qty
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`  AS s
  CROSS JOIN UNNEST(s.hits)     AS h
  CROSS JOIN UNNEST(h.product)  AS p
  WHERE
    p.v2ProductName IS NOT NULL
    AND p.productRevenue IS NOT NULL               -- keeps only bought products
),

henley_buyers AS (
  -- Visitors who bought the YouTube Men’s Vintage Henley
  SELECT DISTINCT fullVisitorId
  FROM july_products
  WHERE LOWER(product_name) LIKE '%vintage henley%'
)

-- Top‑selling product (by quantity) among those visitors, excluding the Henley itself
SELECT
  product_name,
  SUM(qty) AS total_quantity
FROM july_products
WHERE
  fullVisitorId IN (SELECT fullVisitorId FROM henley_buyers)
  AND LOWER(product_name) NOT LIKE '%vintage henley%'
GROUP BY product_name
ORDER BY total_quantity DESC
LIMIT 1;