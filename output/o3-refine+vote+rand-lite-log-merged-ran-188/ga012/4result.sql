/* --------------------------------------------------------------------------
   1.  Pick all purchase events on 30‑Nov‑2020
   2.  Work out the tax‑rate per item‑category
         tax_rate =  Σ(tax_value_in_usd) / Σ(purchase_revenue_in_usd)
   3.  Keep the category with the highest tax‑rate
   4.  Return the transaction‑level information for every purchase event that
       contains at least one item from that top‑tax‑rate category
-------------------------------------------------------------------------- */
WITH purchases AS (
  SELECT
    event_timestamp,
    ecommerce.transaction_id,
    ecommerce.total_item_quantity,
    ecommerce.purchase_revenue_in_usd,
    ecommerce.purchase_revenue,
    ecommerce.tax_value_in_usd,
    items
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
  WHERE event_name = 'purchase'
        AND ecommerce.purchase_revenue_in_usd IS NOT NULL
        AND ecommerce.purchase_revenue_in_usd > 0
),
purchase_items AS (
  SELECT
    p.*,
    i.item_category
  FROM purchases AS p
  LEFT JOIN UNNEST(p.items) AS i
),
category_tax_rate AS (
  SELECT
    item_category,
    SUM(tax_value_in_usd)              AS total_tax_usd,
    SUM(purchase_revenue_in_usd)       AS total_rev_usd,
    SAFE_DIVIDE(SUM(tax_value_in_usd),
                SUM(purchase_revenue_in_usd)) AS tax_rate
  FROM purchase_items
  GROUP BY item_category
  HAVING total_rev_usd > 0
  ORDER BY tax_rate DESC
  LIMIT 1                              -- highest tax‑rate category
),
top_category AS (SELECT item_category FROM category_tax_rate)

SELECT DISTINCT
  p.transaction_id,
  p.total_item_quantity,
  p.purchase_revenue_in_usd,
  p.purchase_revenue
FROM purchases AS p
JOIN UNNEST(p.items) AS i
JOIN top_category AS tc
  ON i.item_category = tc.item_category
ORDER BY p.transaction_id;