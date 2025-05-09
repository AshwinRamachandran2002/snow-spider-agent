-- Other product most frequently bought together with "Google Navy Speckled Tee"
WITH tee_purchases AS (
  SELECT
    event_timestamp,
    user_pseudo_id,
    items
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE
    event_name = 'purchase'
    -- keep only the purchase events that include the tee
    AND EXISTS (
      SELECT 1
      FROM UNNEST(items) AS itm
      WHERE itm.item_name = 'Google Navy Speckled Tee'
    )
)

SELECT
  other.item_name                                AS product_bought_with_tee,
  SUM(other.quantity)                            AS total_quantity
FROM
  tee_purchases
  CROSS JOIN UNNEST(items) AS other
WHERE
  other.item_name IS NOT NULL
  AND other.item_name <> 'Google Navy Speckled Tee'
GROUP BY
  product_bought_with_tee
ORDER BY
  total_quantity DESC
LIMIT 1;