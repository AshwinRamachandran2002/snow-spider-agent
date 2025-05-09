-- Companion product with the highest total quantity bought together with
-- "Google Navy Speckled Tee" in December 2020
WITH tee_transactions AS (
  SELECT DISTINCT
    e.ecommerce.transaction_id AS transaction_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS e
  CROSS JOIN UNNEST(e.items) AS i
  WHERE LOWER(i.item_name) = 'google navy speckled tee'
)

SELECT
  i.item_name,
  SUM(COALESCE(i.quantity, 1)) AS total_quantity
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS t
JOIN tee_transactions
  ON t.ecommerce.transaction_id = tee_transactions.transaction_id
CROSS JOIN UNNEST(t.items) AS i
WHERE LOWER(i.item_name) <> 'google navy speckled tee'
GROUP BY i.item_name
ORDER BY total_quantity DESC
LIMIT 1;