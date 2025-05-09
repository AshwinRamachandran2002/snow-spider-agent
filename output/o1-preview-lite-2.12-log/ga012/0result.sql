WITH top_category AS (
  SELECT
    i.item_category,
    SUM(t.ecommerce.tax_value_in_usd) AS total_tax_usd,
    SUM(t.ecommerce.purchase_revenue_in_usd) AS total_revenue_usd,
    SUM(t.ecommerce.tax_value_in_usd) / SUM(t.ecommerce.purchase_revenue_in_usd) AS tax_rate
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS t
  CROSS JOIN UNNEST(t.items) AS i
  WHERE t.event_date = '20201130'
    AND t.event_name = 'purchase'
    AND t.ecommerce.purchase_revenue_in_usd > 0
  GROUP BY i.item_category
  ORDER BY tax_rate DESC
  LIMIT 1
)
SELECT
  DISTINCT t.ecommerce.transaction_id,
  t.ecommerce.total_item_quantity,
  t.ecommerce.purchase_revenue_in_usd,
  t.ecommerce.purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS t
CROSS JOIN UNNEST(t.items) AS i
WHERE t.event_date = '20201130'
  AND t.event_name = 'purchase'
  AND i.item_category = (SELECT item_category FROM top_category)