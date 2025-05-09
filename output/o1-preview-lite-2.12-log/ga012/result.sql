WITH top_category AS (
  SELECT
    item.item_category,
    SAFE_DIVIDE(SUM(ecommerce.tax_value_in_usd), SUM(ecommerce.purchase_revenue_in_usd)) AS tax_rate
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
    UNNEST(items) AS item
  WHERE
    event_date = '20201130'
    AND event_name = 'purchase'
  GROUP BY
    item.item_category
  ORDER BY
    tax_rate DESC
  LIMIT 1
)
SELECT DISTINCT
  ecommerce.transaction_id,
  ecommerce.total_item_quantity,
  ecommerce.purchase_revenue_in_usd,
  ecommerce.purchase_revenue
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
  UNNEST(items) AS item
JOIN
  top_category
ON
  item.item_category = top_category.item_category
WHERE
  event_date = '20201130'
  AND event_name = 'purchase';