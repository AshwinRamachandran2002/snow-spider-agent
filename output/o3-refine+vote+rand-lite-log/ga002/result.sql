WITH purchases AS (
  -- All purchased items in Nov‑2020, Dec‑2020 and Jan‑2021
  SELECT
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS purchase_date,
    user_pseudo_id,
    itm.item_name,
    itm.quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  CROSS JOIN UNNEST(items) AS itm
  WHERE (_TABLE_SUFFIX LIKE '202011%' OR _TABLE_SUFFIX LIKE '202012%' OR _TABLE_SUFFIX LIKE '202101%')
    AND event_name = 'purchase'
),
buyers AS (
  -- Users who bought Google Red Speckled Tee in each month
  SELECT DISTINCT
    EXTRACT(YEAR  FROM purchase_date) AS yr,
    EXTRACT(MONTH FROM purchase_date) AS mo,
    user_pseudo_id
  FROM purchases
  WHERE item_name = 'Google Red Speckled Tee'
),
other_items AS (
  -- Their other purchased products in the same month
  SELECT
    FORMAT_DATE('%Y-%m', purchase_date) AS month,
    item_name,
    SUM(quantity) AS total_quantity
  FROM purchases p
  JOIN buyers b
    ON p.user_pseudo_id = b.user_pseudo_id
   AND EXTRACT(YEAR  FROM p.purchase_date) = b.yr
   AND EXTRACT(MONTH FROM p.purchase_date) = b.mo
  WHERE p.item_name <> 'Google Red Speckled Tee'
  GROUP BY month, item_name
),
ranked AS (
  -- Rank items by quantity per month
  SELECT
    month,
    item_name,
    total_quantity,
    RANK() OVER (PARTITION BY month ORDER BY total_quantity DESC) AS rnk
  FROM other_items
)
-- Most‑purchased other product(s) each month
SELECT
  month,
  item_name  AS most_purchased_product,
  total_quantity
FROM ranked
WHERE rnk = 1
ORDER BY month;