/* Identify the item_category with the highest average tax-rate on 2020-11-30
   and list the purchase-event details for that category                */

WITH top_category AS (      -- Step 1: find the #1 tax-rate category
  SELECT
    i.item_category
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e,
       UNNEST(e.items) AS i
  WHERE e.event_name = 'purchase'
  GROUP BY i.item_category
  ORDER BY AVG(
           SAFE_DIVIDE(e.ecommerce.tax_value_in_usd,
                        e.ecommerce.purchase_revenue_in_usd)
         ) DESC
  LIMIT 1
)

-- Step 2: pull purchase details for that top category
SELECT DISTINCT
  e.ecommerce.transaction_id,
  e.ecommerce.total_item_quantity,
  e.ecommerce.purchase_revenue_in_usd,
  e.ecommerce.purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
JOIN UNNEST(e.items) AS i
JOIN top_category
  ON i.item_category = top_category.item_category
WHERE e.event_name = 'purchase';