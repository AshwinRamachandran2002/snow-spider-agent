-- Top-tax-rate category on 2020-11-30 and all related purchase transactions
WITH top_category AS (                 -- step-1: find the single highest tax-rate category
  SELECT
    item.item_category,
    SAFE_DIVIDE( SUM(e.ecommerce.tax_value_in_usd),
                 SUM(e.ecommerce.purchase_revenue_in_usd) ) AS tax_rate
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
  JOIN UNNEST(e.items) AS item
  WHERE e.event_name = 'purchase'
  GROUP BY item.item_category
  ORDER BY tax_rate DESC
  LIMIT 1
)

SELECT DISTINCT                          -- step-2: return all purchase events in that category
  e.ecommerce.transaction_id        AS transaction_id,
  e.ecommerce.total_item_quantity   AS total_item_quantity,
  e.ecommerce.purchase_revenue_in_usd,
  e.ecommerce.purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
JOIN UNNEST(e.items) AS item
JOIN top_category AS tc
  ON item.item_category = tc.item_category
WHERE e.event_name = 'purchase'
ORDER BY transaction_id;