-- Product with the highest total quantity bought together with “Google Navy Speckled Tee” in Dec-2020
WITH tee_transactions AS (
  SELECT DISTINCT ecommerce.transaction_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  CROSS JOIN UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name = 'purchase'
    AND LOWER(item.item_name) LIKE '%google%navy%speckled%tee%'
    AND ecommerce.transaction_id IS NOT NULL
)

SELECT
  item.item_name                         AS other_product,
  SUM(item.quantity)                     AS total_quantity_bought_with_tee
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
CROSS JOIN UNNEST(items) AS item
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  AND event_name = 'purchase'
  AND ecommerce.transaction_id IN (SELECT transaction_id FROM tee_transactions)
  AND LOWER(item.item_name) NOT LIKE '%google%navy%speckled%tee%'
GROUP BY other_product
ORDER BY total_quantity_bought_with_tee DESC
LIMIT 1;