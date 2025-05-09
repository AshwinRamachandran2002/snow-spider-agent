WITH purchases AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
  WHERE event_date = '20201130'
    AND event_name = 'purchase'
),
top_category AS (
  SELECT
    it.item_category AS category
  FROM purchases p
  CROSS JOIN UNNEST(p.items) AS it
  GROUP BY category
  HAVING SUM(p.ecommerce.purchase_revenue_in_usd) > 0
  ORDER BY SUM(p.ecommerce.tax_value_in_usd) / SUM(p.ecommerce.purchase_revenue_in_usd) DESC
  LIMIT 1
)
SELECT DISTINCT
  p.ecommerce.transaction_id,
  p.ecommerce.total_item_quantity,
  ROUND(p.ecommerce.purchase_revenue_in_usd, 4) AS purchase_revenue_in_usd,
  ROUND(p.ecommerce.purchase_revenue, 4)        AS purchase_revenue
FROM purchases p
CROSS JOIN UNNEST(p.items) AS it
JOIN top_category tc
  ON it.item_category = tc.category
ORDER BY p.ecommerce.transaction_id;