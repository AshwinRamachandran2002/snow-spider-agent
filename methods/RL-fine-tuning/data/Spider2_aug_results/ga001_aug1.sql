-- Task: Find the total quantity sold of 'Google Navy Speckled Tee' in December 2020.

WITH
  Params AS (
    SELECT 'Google Navy Speckled Tee' AS selected_product
  ),
  PurchaseEvents AS (
    SELECT
      items
    FROM
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE
      _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
      AND event_name = 'purchase'
  )
SELECT
  SUM(items.quantity) AS total_quantity_sold
FROM
  Params,
  PurchaseEvents,
  UNNEST(items) AS items
WHERE
  items.item_name = selected_product;