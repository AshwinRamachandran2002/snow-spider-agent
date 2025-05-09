WITH purchase_events AS (
  -- all December‑2020 purchase events
  SELECT
    ecommerce.transaction_id           AS transaction_id,
    items                              AS items
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE
    _TABLE_SUFFIX BETWEEN '01' AND '31'      -- keep 20201201‑31 tables
    AND event_name = 'purchase'              -- only purchase events
    AND ecommerce.transaction_id IS NOT NULL -- keep rows that actually have a transaction id
),

transactions_with_tee AS (
  -- transactions that contain the Navy Speckled Tee
  SELECT DISTINCT
    transaction_id
  FROM
    purchase_events,
    UNNEST(items) AS item
  WHERE
    item.item_name = 'Google Navy Speckled Tee'
),

other_items AS (
  -- count quantities of every OTHER product bought in those transactions
  SELECT
    item.item_name            AS product_name,
    SUM(item.quantity)        AS total_quantity
  FROM
    purchase_events
    JOIN transactions_with_tee USING (transaction_id),
    UNNEST(items) AS item
  WHERE
    item.item_name IS NOT NULL
    AND item.item_name <> 'Google Navy Speckled Tee'
  GROUP BY
    product_name
)

-- product with the highest total quantity bought together with the tee
SELECT
  product_name,
  total_quantity
FROM
  other_items
ORDER BY
  total_quantity DESC
LIMIT 1;