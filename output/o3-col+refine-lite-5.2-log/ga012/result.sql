/* 1) find the item_category with the highest tax‑rate on 30‑Nov‑2020
   2) list the transactions that contain items from that category          */

WITH purchase_items AS (   -- explode purchase events to the item‑level
  SELECT
    i.item_category                        AS item_category,
    ev.ecommerce.purchase_revenue_in_usd   AS rev_usd,
    ev.ecommerce.tax_value_in_usd          AS tax_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` ev
  CROSS JOIN UNNEST(ev.items) AS i
  WHERE ev.event_name = 'purchase'
    AND ev.ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND ev.ecommerce.tax_value_in_usd        IS NOT NULL
),

ranked_cat AS (           -- pick the category with the highest overall tax‑rate
  SELECT item_category
  FROM (
    SELECT
      item_category,
      SAFE_DIVIDE(SUM(tax_usd), SUM(rev_usd)) AS tax_rate,
      ROW_NUMBER() OVER (ORDER BY SAFE_DIVIDE(SUM(tax_usd), SUM(rev_usd)) DESC) AS rn
    FROM purchase_items
    GROUP BY item_category
  )
  WHERE rn = 1
)

SELECT DISTINCT           -- return transaction‑level details for that top category
  ev.ecommerce.transaction_id,
  ev.ecommerce.total_item_quantity,
  ev.ecommerce.purchase_revenue_in_usd,
  ev.ecommerce.purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` ev
CROSS JOIN UNNEST(ev.items) AS i
JOIN ranked_cat rc
  ON i.item_category = rc.item_category
WHERE ev.event_name = 'purchase';