-- Product with the highest total quantity bought together 
-- with “Google Navy Speckled Tee” in December-2020
WITH tee_transactions AS (
  SELECT DISTINCT ecommerce.transaction_id AS txn_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(items) AS it
  WHERE event_name = 'purchase'
    AND LOWER(it.item_name) LIKE '%google%navy%speckled%tee%'      -- find tee purchases
)

SELECT
  i.item_name,
  SUM(i.quantity) AS total_quantity_with_tee
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` e
JOIN tee_transactions t
  ON e.ecommerce.transaction_id = t.txn_id                         -- keep only tee txns
CROSS JOIN UNNEST(e.items) AS i
WHERE e.event_name = 'purchase'
  AND LOWER(i.item_name) NOT LIKE '%google%navy%speckled%tee%'     -- exclude the tee itself
GROUP BY i.item_name
ORDER BY total_quantity_with_tee DESC
LIMIT 1;