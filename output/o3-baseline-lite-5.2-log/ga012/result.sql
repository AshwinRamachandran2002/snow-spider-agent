WITH purchase_events AS (
  -- all purchase events on 30‑Nov‑2020, exploded by item
  SELECT
    e.ecommerce.transaction_id            AS transaction_id,
    e.ecommerce.total_item_quantity       AS total_item_quantity,
    e.ecommerce.purchase_revenue_in_usd   AS purchase_revenue_in_usd,
    e.ecommerce.purchase_revenue          AS purchase_revenue,
    e.ecommerce.tax_value_in_usd          AS tax_value_usd,
    itm.item_category                     AS item_category
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e
  CROSS JOIN UNNEST(e.items) AS itm
  WHERE e.event_name = 'purchase'
        AND e.ecommerce.purchase_revenue_in_usd IS NOT NULL
        AND e.ecommerce.purchase_revenue_in_usd > 0
        AND e.ecommerce.tax_value_in_usd IS NOT NULL
),
category_tax AS (
  -- tax rate per item category
  SELECT
    item_category,
    SUM(tax_value_usd)                    AS total_tax_usd,
    SUM(purchase_revenue_in_usd)          AS total_revenue_usd,
    SAFE_DIVIDE(SUM(tax_value_usd),
                SUM(purchase_revenue_in_usd)) AS tax_rate
  FROM purchase_events
  GROUP BY item_category
),
top_category AS (
  -- category with the highest tax rate
  SELECT item_category
  FROM category_tax
  ORDER BY tax_rate DESC
  LIMIT 1
)
-- return purchase‑event details within that top category
SELECT DISTINCT
  pe.transaction_id,
  pe.total_item_quantity,
  pe.purchase_revenue_in_usd,
  pe.purchase_revenue
FROM purchase_events AS pe
JOIN top_category  AS tc
  ON pe.item_category = tc.item_category
ORDER BY pe.transaction_id;