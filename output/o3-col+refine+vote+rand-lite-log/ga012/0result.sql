-- 1) find the item_category with the highest tax-rate on 30-Nov-2020
-- 2) return all purchase events that include at least one item in that category
WITH top_category AS (
  SELECT
    item.item_category,
    SAFE_DIVIDE(SUM(ecommerce.tax_value_in_usd),
                SUM(ecommerce.purchase_revenue_in_usd)) AS tax_rate
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
       UNNEST(items) AS item
  WHERE event_name = 'purchase'
    AND ecommerce.tax_value_in_usd       IS NOT NULL
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
  GROUP BY item_category
  ORDER BY tax_rate DESC
  LIMIT 1
)

SELECT DISTINCT
  e.ecommerce.transaction_id       AS transaction_id,
  e.ecommerce.total_item_quantity  AS total_item_quantity,
  e.ecommerce.purchase_revenue_in_usd,
  e.ecommerce.purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
JOIN UNNEST(e.items) AS item
JOIN top_category t
  ON item.item_category = t.item_category
WHERE e.event_name = 'purchase';