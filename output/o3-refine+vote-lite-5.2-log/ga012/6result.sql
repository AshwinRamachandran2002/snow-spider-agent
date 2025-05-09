-- 1) work only with the 30‑Nov‑2020 table
-- 2) look at “purchase” events, bring the ecommerce
--    money fields together with every item_category
-- 3) work out the tax‑rate per category
-- 4) pick the single category with the highest tax‑rate
-- 5) return all purchase events that belong to that
--    top‑tax‑rate category (one row per transaction)

WITH purchase_events AS (        -- all purchase rows on 2020‑11‑30
  SELECT
    event_timestamp,
    ecommerce.tax_value_in_usd          AS tax_usd,
    ecommerce.purchase_revenue_in_usd   AS revenue_usd,
    ecommerce.purchase_revenue          AS revenue,
    ecommerce.total_item_quantity       AS total_qty,
    ecommerce.transaction_id            AS transaction_id,
    itm.item_category                   AS item_category
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
        UNNEST(items) AS itm
  WHERE event_name = 'purchase'
),

category_rates AS (              -- tax‑rate per item category
  SELECT
    item_category,
    SUM(tax_usd)      AS total_tax_usd,
    SUM(revenue_usd)  AS total_revenue_usd,
    SAFE_DIVIDE(SUM(tax_usd), SUM(revenue_usd)) AS tax_rate
  FROM (                         -- de‑duplicate per event & category
    SELECT DISTINCT
      event_timestamp,
      item_category,
      tax_usd,
      revenue_usd
    FROM purchase_events
    WHERE revenue_usd IS NOT NULL AND revenue_usd <> 0
  )
  GROUP BY item_category
),

top_category AS (                -- keep only the highest‑tax‑rate one
  SELECT item_category
  FROM   category_rates
  ORDER  BY tax_rate DESC
  LIMIT  1
)

SELECT DISTINCT                   -- final answer
  pe.transaction_id,
  pe.total_qty          AS total_item_quantity,
  pe.revenue_usd        AS purchase_revenue_in_usd,
  pe.revenue            AS purchase_revenue
FROM  purchase_events pe
JOIN  top_category tc
  ON  pe.item_category = tc.item_category
ORDER BY pe.transaction_id;