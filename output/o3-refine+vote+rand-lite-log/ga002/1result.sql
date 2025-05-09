-- Most purchased OTHER product (and its total quantity) among customers
-- who bought the “Google Red Speckled Tee”, for each month
-- Nov‑2020, Dec‑2020 and Jan‑2021.

WITH purchases AS (
  -- All purchase‑item rows in the three‑month window
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS month,
    user_pseudo_id,
    itm.item_name,
    IFNULL(itm.quantity, 0) AS quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(items) AS itm
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
        AND event_name = 'purchase'
),
red_shirt_buyers AS (
  -- Shoppers who bought the Google Red Speckled Tee (per month)
  SELECT DISTINCT month, user_pseudo_id
  FROM purchases
  WHERE item_name = 'Google Red Speckled Tee'
),
other_item_totals AS (
  -- Aggregate quantities of all OTHER items bought by those shoppers
  SELECT
    p.month,
    p.item_name,
    SUM(p.quantity) AS total_qty
  FROM purchases p
  JOIN red_shirt_buyers r
    ON  p.month = r.month
    AND p.user_pseudo_id = r.user_pseudo_id
  WHERE p.item_name != 'Google Red Speckled Tee'
  GROUP BY p.month, p.item_name
),
ranked AS (
  -- Rank items by quantity per month
  SELECT
    month,
    item_name,
    total_qty,
    ROW_NUMBER() OVER (PARTITION BY month
                       ORDER BY total_qty DESC, item_name) AS rn
  FROM other_item_totals
)
-- Top (most purchased) other product for each month
SELECT
  month,
  item_name  AS most_purchased_other_product,
  total_qty  AS total_quantity
FROM ranked
WHERE rn = 1
ORDER BY month;