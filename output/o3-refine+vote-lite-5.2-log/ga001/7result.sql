WITH tee_purchases AS (
  -- All December‑2020 purchase events that include “Google Navy Speckled Tee”
  SELECT
    ecommerce.transaction_id,
    items
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE
    event_name = 'purchase'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(items) AS it
      WHERE it.item_name = 'Google Navy Speckled Tee'
    )
),
other_items AS (
  -- Every other item bought in those same transactions
  SELECT
    it.item_name                              AS product,
    SUM(COALESCE(it.quantity,1))              AS total_quantity
  FROM
    tee_purchases,
    UNNEST(items) AS it
  WHERE
    it.item_name <> 'Google Navy Speckled Tee'
  GROUP BY
    product
)
SELECT
  product  AS item_name,
  total_quantity
FROM
  other_items
ORDER BY
  total_quantity DESC,
  item_name
LIMIT 1;