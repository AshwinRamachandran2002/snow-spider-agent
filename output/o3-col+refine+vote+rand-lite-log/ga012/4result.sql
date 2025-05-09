-- 1) find the item_category whose average tax-rate
--    (tax_value_in_usd / purchase_revenue_in_usd) is highest
-- 2) list every purchase event (transaction) that contains at least
--    one item of that top-tax-rate category
WITH purchases AS (
  SELECT
    e.ecommerce.transaction_id,
    e.ecommerce.total_item_quantity,
    e.ecommerce.purchase_revenue_in_usd,
    e.ecommerce.purchase_revenue,
    item.item_category,
    SAFE_DIVIDE(e.ecommerce.tax_value_in_usd,
                e.ecommerce.purchase_revenue_in_usd) AS tax_rate
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
  JOIN UNNEST(e.items) AS item
  WHERE e.event_name = 'purchase'
    AND e.ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND e.ecommerce.tax_value_in_usd     IS NOT NULL
),
top_category AS (
  SELECT item_category
  FROM purchases
  GROUP BY item_category
  ORDER BY AVG(tax_rate) DESC
  LIMIT 1
)
SELECT DISTINCT
  p.transaction_id,
  p.total_item_quantity,
  p.purchase_revenue_in_usd,
  p.purchase_revenue
FROM purchases p
JOIN top_category tc
  ON p.item_category = tc.item_category;