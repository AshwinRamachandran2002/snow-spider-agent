-- Top‑selling product (by units sold) bought by the same customers
-- who purchased “YouTube Men’s Vintage Henley” during July‑2017,
-- excluding the Henley itself
WITH july_products AS (
  -- explode July‑2017 sessions into individual products that generated revenue
  SELECT
    fullVisitorId,
    LOWER(p.v2ProductName)            AS product_name_lc,
    p.v2ProductName                   AS product_name,
    COALESCE(p.productQuantity, 1)    AS qty,
    COALESCE(p.productRevenue, 0)     AS revenue_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
       UNNEST(hits)   AS h,
       UNNEST(h.product) AS p
  WHERE p.productRevenue IS NOT NULL            -- keep only purchased items
),

henley_buyers AS (
  -- visitors who bought the Henley in July‑2017
  SELECT DISTINCT fullVisitorId
  FROM july_products
  WHERE product_name_lc LIKE '%vintage henley%'
),

other_purchases AS (
  -- all OTHER products those visitors bought in July‑2017
  SELECT
    jp.product_name,
    SUM(jp.qty)             AS total_units,
    SUM(jp.revenue_micro)   AS total_revenue_micro
  FROM july_products jp
  JOIN henley_buyers  USING (fullVisitorId)
  WHERE jp.product_name_lc NOT LIKE '%vintage henley%'
  GROUP BY jp.product_name
)

SELECT
  product_name         AS top_selling_product,
  total_units,
  total_revenue_micro / 1e6 AS total_revenue      -- convert from micros to currency units
FROM other_purchases
ORDER BY total_units DESC, total_revenue_micro DESC
LIMIT 1;