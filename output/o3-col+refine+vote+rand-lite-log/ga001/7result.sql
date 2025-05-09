/* Companion product with the greatest total quantity bought together
   with the “Google Navy Speckled Tee” during December-2020        */

WITH tee_transactions AS (
  SELECT DISTINCT ecommerce.transaction_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(items) AS itm
  WHERE ecommerce.transaction_id IS NOT NULL
    AND LOWER(itm.item_name) LIKE '%navy%speckled%tee%'
)

SELECT
  itm.item_name AS companion_product,
  SUM(itm.quantity) AS total_quantity
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
     UNNEST(items) AS itm
WHERE ecommerce.transaction_id IN (SELECT transaction_id FROM tee_transactions)
  AND LOWER(itm.item_name) NOT LIKE '%navy%speckled%tee%'
GROUP BY itm.item_name
ORDER BY total_quantity DESC
LIMIT 1;