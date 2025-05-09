-- Product (other than the tee itself) most frequently bought in the
-- same December‑2020 transactions as “Google Navy Speckled Tee”
WITH tee_transactions AS (
  SELECT DISTINCT ecommerce.transaction_id
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
       ,UNNEST(items) AS i
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'   -- December 2020
    AND event_name = 'purchase'
    AND LOWER(i.item_name) = 'google navy speckled tee'   -- the tee
    AND ecommerce.transaction_id IS NOT NULL              -- keep only real TXNs
),

other_products AS (
  SELECT
    item.item_name                 AS product_name,
    SUM(item.quantity)             AS total_quantity
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
       ,UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name = 'purchase'
    AND ecommerce.transaction_id IN (SELECT transaction_id FROM tee_transactions)
    AND LOWER(item.item_name) <> 'google navy speckled tee'   -- exclude the tee
  GROUP BY item.item_name
)

SELECT
  product_name        AS product_purchased_with_tee,
  total_quantity      AS total_quantity_alongside_tee
FROM  other_products
ORDER BY total_quantity DESC, product_name
LIMIT 1;