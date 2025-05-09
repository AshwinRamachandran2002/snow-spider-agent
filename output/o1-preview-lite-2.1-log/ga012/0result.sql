WITH highest_tax_rate_category AS (
  SELECT
    i.item_category
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS t,
    UNNEST(t.items) AS i
  WHERE
    t.event_name = 'purchase'
    AND t.ecommerce.purchase_revenue > 0
    AND t.ecommerce.tax_value IS NOT NULL
  GROUP BY
    i.item_category
  ORDER BY
    SUM(t.ecommerce.tax_value) / SUM(t.ecommerce.purchase_revenue) DESC
  LIMIT 1
)
SELECT
  t.ecommerce.transaction_id AS transaction_id,
  SUM(i.quantity) AS total_item_quantity,
  t.ecommerce.purchase_revenue AS purchase_revenue
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS t,
  UNNEST(t.items) AS i,
  highest_tax_rate_category AS htc
WHERE
  t.event_name = 'purchase'
  AND i.item_category = htc.item_category
  AND t.ecommerce.transaction_id IS NOT NULL
GROUP BY
  transaction_id,
  purchase_revenue;