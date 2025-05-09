/*  Product most frequently bought together with “Google Navy Speckled Tee”
    in purchase transactions that occurred in December 2020                */

WITH dec2020_purchases AS (
  -- All December‑2020 purchase events
  SELECT
    ecommerce.transaction_id   AS transaction_id,
    items
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE
    event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL
),

tee_transactions AS (
  -- Transactions that include the Google Navy Speckled Tee
  SELECT DISTINCT
    transaction_id
  FROM
    dec2020_purchases,
    UNNEST(items) AS itm
  WHERE
    itm.item_name = 'Google Navy Speckled Tee'
),

other_items AS (
  -- All other items bought in those same transactions
  SELECT
    itm.item_name,
    itm.quantity
  FROM
    dec2020_purchases
    JOIN tee_transactions USING (transaction_id),
    UNNEST(items) AS itm
  WHERE
    itm.item_name <> 'Google Navy Speckled Tee'
)

SELECT
  item_name        AS other_product,
  SUM(quantity)    AS total_quantity
FROM
  other_items
GROUP BY
  other_product
ORDER BY
  total_quantity DESC,
  other_product
LIMIT 1;