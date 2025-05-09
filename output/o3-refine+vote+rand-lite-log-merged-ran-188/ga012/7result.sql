-- 1) find the item_category with the highest tax‑rate on 2020‑11‑30
-- 2) list every purchase event that contains that category together with the
--    requested ecommerce fields

WITH purchases AS (
  SELECT
    ecommerce,              -- STRUCT that holds tax / revenue / qty / txn‑id …
    items                   -- ARRAY<STRUCT<…item_category…>>
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
  WHERE event_name = 'purchase'
        -- keep only rows that have revenue to avoid div‑by‑0
        AND ecommerce.purchase_revenue_in_usd IS NOT NULL
        AND ecommerce.purchase_revenue_in_usd > 0
),

-- explode items so that each item_category inherits the event‑level tax / revenue
item_level AS (
  SELECT
    i.item_category                        AS category,
    p.ecommerce.tax_value_in_usd           AS tax_usd,
    p.ecommerce.purchase_revenue_in_usd    AS revenue_usd
  FROM purchases AS p
  LEFT JOIN UNNEST(p.items) AS i
),

-- aggregate to get tax‑rate per category
category_tax_rate AS (
  SELECT
    category,
    SUM(tax_usd)    AS total_tax_usd,
    SUM(revenue_usd) AS total_revenue_usd,
    SUM(tax_usd) / SUM(revenue_usd) AS tax_rate
  FROM item_level
  WHERE category IS NOT NULL
  GROUP BY category
),

-- the category with the highest tax‑rate
top_category AS (
  SELECT category
  FROM category_tax_rate
  ORDER BY tax_rate DESC
  LIMIT 1
)

-- final answer: purchase events that contain the top‑tax‑rate category
SELECT DISTINCT
  p.ecommerce.transaction_id          AS transaction_id,
  p.ecommerce.total_item_quantity     AS total_item_quantity,
  p.ecommerce.purchase_revenue_in_usd AS purchase_revenue_in_usd,
  p.ecommerce.purchase_revenue        AS purchase_revenue
FROM purchases AS p
LEFT JOIN UNNEST(p.items) AS i
JOIN top_category AS t
  ON i.item_category = t.category
ORDER BY transaction_id;