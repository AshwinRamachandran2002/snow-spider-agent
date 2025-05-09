WITH december_purchases AS (
  -- All December‑2020 purchase lines
  SELECT
    ecommerce.transaction_id      AS transaction_id,
    i.item_name                   AS item_name,
    COALESCE(i.quantity, 0)       AS quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(items) AS i
  WHERE event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL
),

navy_transactions AS (
  -- Transactions that include the Google Navy Speckled Tee
  SELECT DISTINCT transaction_id
  FROM december_purchases
  WHERE item_name = 'Google Navy Speckled Tee'
)

-- Aggregate quantities of other products bought in the same transactions
SELECT
  dp.item_name       AS other_product,
  SUM(dp.quantity)   AS total_quantity
FROM december_purchases AS dp
JOIN navy_transactions USING (transaction_id)
WHERE dp.item_name <> 'Google Navy Speckled Tee'
GROUP BY other_product
ORDER BY total_quantity DESC, other_product
LIMIT 1;