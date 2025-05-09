-- 1) work only with Nov‑30‑2020 purchase events
-- 2) find which item_category has the highest   tax_value_usd / purchase_revenue_usd
-- 3) list the purchase‑event details that belong to that top‑tax‑rate category
WITH purchases AS (
  SELECT
      ecommerce.transaction_id                          AS transaction_id,
      ecommerce.total_item_quantity                     AS total_item_quantity,
      ecommerce.purchase_revenue_in_usd                 AS purchase_revenue_in_usd,
      ecommerce.purchase_revenue                        AS purchase_revenue,
      ecommerce.tax_value_in_usd                        AS tax_value_in_usd,
      item.item_category                                AS item_category
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
        UNNEST(items) AS item
  WHERE event_name = 'purchase'
        AND ecommerce.purchase_revenue_in_usd IS NOT NULL
        AND ecommerce.purchase_revenue_in_usd > 0
        AND item.item_category IS NOT NULL
),
category_tax AS (
  SELECT
      item_category,
      SUM(tax_value_in_usd)          AS total_tax_usd,
      SUM(purchase_revenue_in_usd)   AS total_revenue_usd,
      SUM(tax_value_in_usd) / SUM(purchase_revenue_in_usd) AS tax_rate
  FROM purchases
  GROUP BY item_category
),
top_category AS (
  SELECT item_category
  FROM category_tax
  ORDER BY tax_rate DESC
  LIMIT 1
)
SELECT DISTINCT
    p.transaction_id,
    p.total_item_quantity,
    p.purchase_revenue_in_usd,
    p.purchase_revenue
FROM purchases p
JOIN top_category t
  ON p.item_category = t.item_category
ORDER BY p.transaction_id;