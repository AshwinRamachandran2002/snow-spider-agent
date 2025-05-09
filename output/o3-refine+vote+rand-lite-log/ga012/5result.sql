WITH purchase_events AS (
  -- all purchase events on 2020‑11‑30
  SELECT
    ecommerce,          -- transaction / revenue / tax info
    items               -- item‑level details
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
  WHERE event_name = 'purchase'
),

/*  tax‑to‑revenue ratio per item category  */
category_rates AS (
  SELECT
    itm.item_category                         AS item_category,
    SUM(pe.ecommerce.tax_value_in_usd)        AS total_tax_usd,
    SUM(pe.ecommerce.purchase_revenue_in_usd) AS total_rev_usd,
    SAFE_DIVIDE(
      SUM(pe.ecommerce.tax_value_in_usd),
      SUM(pe.ecommerce.purchase_revenue_in_usd)
    )                                         AS tax_rate
  FROM purchase_events pe
  CROSS JOIN UNNEST(pe.items) AS itm
  WHERE itm.item_category IS NOT NULL
  GROUP BY item_category
),

/*  category with the highest tax rate  */
top_category AS (
  SELECT item_category
  FROM category_rates
  ORDER BY tax_rate DESC
  LIMIT 1
)

/*  purchase‑event details for transactions that include that category  */
SELECT DISTINCT
  pe.ecommerce.transaction_id      AS transaction_id,
  pe.ecommerce.total_item_quantity AS total_item_quantity,
  pe.ecommerce.purchase_revenue_in_usd,
  pe.ecommerce.purchase_revenue
FROM purchase_events pe
JOIN UNNEST(pe.items)   AS itm              -- look at every item in the event
JOIN top_category       AS tc
  ON itm.item_category = tc.item_category;  -- keep only events that contain it