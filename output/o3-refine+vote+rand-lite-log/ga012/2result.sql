-- 1) work only with purchase events that happened on 2020‑11‑30
-- 2) find the item_category that shows the highest tax‑rate
--    tax‑rate = SUM(tax_value_in_usd) / SUM(purchase_revenue_in_usd)
-- 3) return every purchase event (transaction) that contains at least
--    one item from that top‑tax‑rate category, together with the
--    requested metrics

WITH purchase_events AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
  WHERE event_name = 'purchase'
        -- keep rows where both pieces exist so the rate can be calculated
        AND ecommerce.purchase_revenue_in_usd IS NOT NULL
        AND ecommerce.tax_value_in_usd      IS NOT NULL
),

category_tax_rate AS (
  SELECT
    itm.item_category                              AS item_category,
    SUM(ecom.tax_value_in_usd)                     AS total_tax_usd,
    SUM(ecom.purchase_revenue_in_usd)              AS total_rev_usd,
    SAFE_DIVIDE(SUM(ecom.tax_value_in_usd),
                SUM(ecom.purchase_revenue_in_usd)) AS tax_rate
  FROM purchase_events pe
  CROSS JOIN UNNEST(pe.items) AS itm
  CROSS JOIN UNNEST([pe.ecommerce]) AS ecom        -- pull the ecommerce struct
  GROUP BY itm.item_category
),

top_category AS (
  SELECT item_category
  FROM category_tax_rate
  ORDER BY tax_rate DESC
  LIMIT 1
)

SELECT DISTINCT
  pe.ecommerce.transaction_id            AS transaction_id,
  pe.ecommerce.total_item_quantity,
  pe.ecommerce.purchase_revenue_in_usd,
  pe.ecommerce.purchase_revenue
FROM purchase_events pe
CROSS JOIN UNNEST(pe.items) AS itm
JOIN   top_category tc
  ON   itm.item_category = tc.item_category
WHERE pe.ecommerce.transaction_id IS NOT NULL
ORDER BY pe.ecommerce.transaction_id;