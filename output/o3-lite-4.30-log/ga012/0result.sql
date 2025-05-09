WITH top_category AS (
  SELECT
    i.item_category,
    AVG(evt.ecommerce.tax_value_in_usd / evt.ecommerce.purchase_revenue_in_usd) AS avg_tax_rate
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS evt
  CROSS JOIN UNNEST(evt.items) AS i
  WHERE evt.event_name = 'purchase'
    AND evt.event_date = '20201130'
    AND evt.ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND evt.ecommerce.purchase_revenue_in_usd > 0
    AND evt.ecommerce.tax_value_in_usd IS NOT NULL
  GROUP BY i.item_category
  ORDER BY avg_tax_rate DESC
  LIMIT 1
)
SELECT DISTINCT
  evt.ecommerce.transaction_id,
  evt.ecommerce.total_item_quantity,
  ROUND(evt.ecommerce.purchase_revenue_in_usd, 4)  AS purchase_revenue_in_usd,
  ROUND(evt.ecommerce.purchase_revenue,     4)  AS purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS evt
CROSS JOIN UNNEST(evt.items) AS i
JOIN top_category tc
  ON i.item_category = tc.item_category
WHERE evt.event_name = 'purchase'
  AND evt.event_date = '20201130';