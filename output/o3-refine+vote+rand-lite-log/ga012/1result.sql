-- 1.  Pick all purchase events from 30‑Nov‑2020
-- 2.  Work out the tax‑rate per item category
-- 3.  Keep the category with the highest tax‑rate
-- 4.  Return the requested purchase‑event details for that category
WITH purchase_events AS (
  SELECT
    e.ecommerce.tax_value_in_usd          AS tax_usd,
    e.ecommerce.purchase_revenue_in_usd   AS revenue_usd,
    e.ecommerce.total_item_quantity       AS total_item_quantity,
    e.ecommerce.transaction_id            AS transaction_id,
    e.ecommerce.purchase_revenue          AS purchase_revenue,
    itm.item_category                     AS item_category
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` e
  CROSS JOIN UNNEST(e.items) AS itm
  WHERE e.event_name = 'purchase'
        -- keep rows that can form a meaningful tax rate
        AND e.ecommerce.purchase_revenue_in_usd IS NOT NULL
        AND e.ecommerce.purchase_revenue_in_usd > 0
        AND itm.item_category IS NOT NULL
),

category_tax_rate AS (
  SELECT
    item_category,
    SUM(tax_usd)    AS total_tax_usd,
    SUM(revenue_usd) AS total_revenue_usd,
    SAFE_DIVIDE(SUM(tax_usd), SUM(revenue_usd)) AS tax_rate
  FROM purchase_events
  GROUP BY item_category
),

top_category AS (
  SELECT item_category
  FROM category_tax_rate
  ORDER BY tax_rate DESC
  LIMIT 1
)

SELECT DISTINCT
  pe.transaction_id,
  pe.total_item_quantity,
  pe.revenue_usd      AS purchase_revenue_in_usd,
  pe.purchase_revenue
FROM purchase_events pe
JOIN top_category tc
  ON pe.item_category = tc.item_category
ORDER BY pe.transaction_id;