WITH top_category AS (
  SELECT
    item.item_category
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
       UNNEST(items) AS item
  WHERE event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd > 0
  GROUP BY item.item_category
  ORDER BY AVG(SAFE_DIVIDE(ecommerce.tax_value_in_usd, ecommerce.purchase_revenue_in_usd)) DESC
  LIMIT 1
)

SELECT
  ecommerce.transaction_id,
  ecommerce.total_item_quantity,
  ecommerce.purchase_revenue_in_usd,
  ecommerce.purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
     UNNEST(items) AS item,
     top_category
WHERE event_name = 'purchase'
  AND item.item_category = top_category.item_category