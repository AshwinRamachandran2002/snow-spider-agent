-- 1) Find the item_category whose purchase events bear the highest overall tax-to-revenue ratio
WITH top_category AS (
  SELECT
    itm.item_category AS cat
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` ev
  CROSS JOIN UNNEST(ev.items) AS itm
  WHERE ev.event_name = 'purchase'
        AND ev.ecommerce.purchase_revenue_in_usd IS NOT NULL
        AND ev.ecommerce.purchase_revenue_in_usd > 0               -- avoid divide-by-zero
  GROUP BY itm.item_category
  ORDER BY SAFE_DIVIDE(SUM(ev.ecommerce.tax_value_in_usd),
                       SUM(ev.ecommerce.purchase_revenue_in_usd)) DESC
  LIMIT 1
)

-- 2) Return every purchase whose items belong to that top-tax-rate category
SELECT DISTINCT
       ev.ecommerce.transaction_id      AS transaction_id,
       ev.ecommerce.total_item_quantity AS total_item_quantity,
       ev.ecommerce.purchase_revenue_in_usd,
       ev.ecommerce.purchase_revenue
FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` ev
JOIN  top_category tc ON TRUE
WHERE ev.event_name = 'purchase'
  AND EXISTS (SELECT 1
              FROM UNNEST(ev.items) item
              WHERE item.item_category = tc.cat);