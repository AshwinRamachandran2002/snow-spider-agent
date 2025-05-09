WITH highest_tax_category AS (
  SELECT item_category
  FROM (
    SELECT
      item.item_category,
      SAFE_DIVIDE(SUM(ecommerce.tax_value), SUM(ecommerce.purchase_revenue)) AS tax_rate
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
      UNNEST(items) AS item
    WHERE
      event_date = '20201130'
      AND item.item_category IS NOT NULL
      AND item.item_category != ''
      AND ecommerce.tax_value IS NOT NULL
      AND ecommerce.purchase_revenue IS NOT NULL
      AND ecommerce.purchase_revenue != 0
    GROUP BY item.item_category
    ORDER BY tax_rate DESC
    LIMIT 1
  )
)
SELECT DISTINCT
  ecommerce.transaction_id,
  ecommerce.total_item_quantity,
  ecommerce.purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
  UNNEST(items) AS item,
  highest_tax_category
WHERE
  event_date = '20201130'
  AND item.item_category = highest_tax_category.item_category
  AND ecommerce.transaction_id IS NOT NULL
  AND ecommerce.total_item_quantity IS NOT NULL
  AND ecommerce.purchase_revenue IS NOT NULL