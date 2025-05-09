WITH purchases AS (
  SELECT
    e.ecommerce.transaction_id           AS transaction_id,
    e.ecommerce.total_item_quantity      AS total_item_quantity,
    e.ecommerce.purchase_revenue_in_usd  AS purchase_revenue_in_usd,
    e.ecommerce.purchase_revenue         AS purchase_revenue,
    e.ecommerce.tax_value_in_usd         AS tax_value_in_usd,
    it.item_category                     AS item_category
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
  CROSS JOIN UNNEST(e.items) AS it
  WHERE e.event_date = '20201130'
    AND e.event_name = 'purchase'
    AND e.ecommerce.purchase_revenue_in_usd > 0
),
tax_by_category AS (
  SELECT
    item_category,
    SUM(tax_value_in_usd) / SUM(purchase_revenue_in_usd) AS tax_rate
  FROM purchases
  GROUP BY item_category
),
top_category AS (
  SELECT item_category
  FROM tax_by_category
  ORDER BY tax_rate DESC
  LIMIT 1
)
SELECT DISTINCT
  p.transaction_id,
  p.total_item_quantity,
  ROUND(p.purchase_revenue_in_usd, 4) AS purchase_revenue_in_usd,
  ROUND(p.purchase_revenue, 4)        AS purchase_revenue
FROM purchases AS p
JOIN top_category AS t
ON  p.item_category = t.item_category
ORDER BY p.transaction_id;