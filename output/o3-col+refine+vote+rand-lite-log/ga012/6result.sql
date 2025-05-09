-- Top-tax-rate category on 2020-11-30 and the purchase events inside it
WITH top_category AS (
  SELECT
    itm.item_category AS category,
    SUM(e.ecommerce.tax_value_in_usd) /
    SUM(e.ecommerce.purchase_revenue_in_usd)     AS tax_rate
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
  JOIN UNNEST(e.items) AS itm
  WHERE e.event_name = 'purchase'
    AND e.ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND e.ecommerce.purchase_revenue_in_usd > 0
  GROUP BY category
  ORDER BY tax_rate DESC
  LIMIT 1
)

SELECT DISTINCT
  e.ecommerce.transaction_id,
  e.ecommerce.total_item_quantity,
  e.ecommerce.purchase_revenue_in_usd,
  e.ecommerce.purchase_revenue
FROM   `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
JOIN   UNNEST(e.items) AS itm
JOIN   top_category    AS t
  ON   itm.item_category = t.category
WHERE  e.event_name = 'purchase';