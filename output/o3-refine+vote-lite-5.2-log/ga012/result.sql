-- 1) find the item_category whose purchases carried the highest tax‑to‑revenue ratio
-- 2) list every purchase (transaction) that contains at least one item of that category,
--    returning its transaction_id, total_item_quantity, purchase_revenue_in_usd and purchase_revenue

WITH purchases AS (
  SELECT
    e.ecommerce.transaction_id                           AS transaction_id,
    e.ecommerce.total_item_quantity                      AS total_item_quantity,
    e.ecommerce.purchase_revenue_in_usd                  AS purchase_revenue_in_usd,
    e.ecommerce.purchase_revenue                         AS purchase_revenue,
    e.ecommerce.tax_value_in_usd                         AS tax_value_in_usd,
    i.item_category                                      AS item_category
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`  AS e
  CROSS JOIN UNNEST(e.items) AS i
  WHERE e.event_name = 'purchase'
),

-- tax‑rate (tax / revenue) per item_category
category_rates AS (
  SELECT
    item_category,
    SUM(tax_value_in_usd)        AS total_tax_usd,
    SUM(purchase_revenue_in_usd) AS total_revenue_usd,
    SAFE_DIVIDE(SUM(tax_value_in_usd),
                SUM(purchase_revenue_in_usd)) AS tax_rate
  FROM purchases
  GROUP BY item_category
),

-- top‑tax‑rate category
top_category AS (
  SELECT item_category
  FROM category_rates
  ORDER BY tax_rate DESC
  LIMIT 1
)

-- final result: every purchase containing the top‑tax‑rate category
SELECT DISTINCT
  p.transaction_id,
  p.total_item_quantity,
  p.purchase_revenue_in_usd,
  p.purchase_revenue
FROM purchases AS p
JOIN top_category AS t
  ON p.item_category = t.item_category
ORDER BY p.transaction_id;