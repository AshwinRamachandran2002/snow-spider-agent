-- Identify the item category with the highest tax-rate on 2020-11-30
-- and return the purchase-event details for that category
WITH category_rates AS (
  SELECT
    i.item_category,
    SUM(ecommerce.tax_value_in_usd)     AS total_tax_usd,
    SUM(ecommerce.purchase_revenue_in_usd) AS total_rev_usd,
    SAFE_DIVIDE(SUM(ecommerce.tax_value_in_usd),
                SUM(ecommerce.purchase_revenue_in_usd))        AS tax_rate
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
       UNNEST(items) AS i
  WHERE event_name = 'purchase'
        AND ecommerce.tax_value_in_usd IS NOT NULL
        AND ecommerce.purchase_revenue_in_usd IS NOT NULL
  GROUP BY i.item_category
),
top_category AS (
  SELECT item_category
  FROM category_rates
  ORDER BY tax_rate DESC
  LIMIT 1
)
SELECT DISTINCT
  e.ecommerce.transaction_id,
  e.ecommerce.total_item_quantity,
  e.ecommerce.purchase_revenue_in_usd,
  e.ecommerce.purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
JOIN UNNEST(e.items) AS i
JOIN top_category t
  ON i.item_category = t.item_category
WHERE e.event_name = 'purchase'
ORDER BY e.ecommerce.transaction_id;