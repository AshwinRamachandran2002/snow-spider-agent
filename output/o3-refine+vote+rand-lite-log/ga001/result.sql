WITH december_purchases AS (
  -- All purchase events in December‑2020
  SELECT
    user_pseudo_id,
    event_timestamp,
    items
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'purchase'
),

tee_purchase_events AS (
  -- Purchase events that include the Google Navy Speckled Tee
  SELECT DISTINCT
    user_pseudo_id,
    event_timestamp
  FROM december_purchases,
  UNNEST(items) AS itm
  WHERE itm.item_name = 'Google Navy Speckled Tee'
),

other_items AS (
  -- Items bought in the same transactions, excluding the Tee itself
  SELECT
    oi.item_name  AS product_name,
    oi.quantity   AS quantity
  FROM december_purchases  dp
  JOIN tee_purchase_events tp
    ON  dp.user_pseudo_id  = tp.user_pseudo_id
    AND dp.event_timestamp = tp.event_timestamp
  CROSS JOIN UNNEST(dp.items) AS oi
  WHERE oi.item_name <> 'Google Navy Speckled Tee'
)

SELECT
  product_name,
  SUM(quantity) AS total_quantity
FROM other_items
GROUP BY product_name
ORDER BY total_quantity DESC
LIMIT 1;