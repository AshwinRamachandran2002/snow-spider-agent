-- 1) find the item_category with the highest average tax-rate on Nov-30-2020
-- 2) list every purchase event that falls in that category
WITH purchase_events AS (
  SELECT
    ecommerce.transaction_id,
    ecommerce.total_item_quantity,
    ecommerce.purchase_revenue_in_usd,
    ecommerce.purchase_revenue,
    ecommerce.tax_value_in_usd,
    itm.item_category,
    ecommerce.tax_value_in_usd / NULLIF(ecommerce.purchase_revenue_in_usd, 0) AS tax_rate
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
       UNNEST(items) AS itm
  WHERE event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd > 0          -- avoid divide-by-zero
),
top_category AS (
  SELECT item_category
  FROM purchase_events
  GROUP BY item_category
  ORDER BY AVG(tax_rate) DESC
  LIMIT 1
)
SELECT DISTINCT
  transaction_id,
  total_item_quantity,
  purchase_revenue_in_usd,
  purchase_revenue
FROM purchase_events
WHERE item_category = (SELECT item_category FROM top_category);