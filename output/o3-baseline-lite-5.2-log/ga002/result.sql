/* Top‑purchased “other” products (and their quantities) each month
   among customers who bought the “Google Red Speckled Tee”
   for the three months starting November‑2020                */

WITH purchased_items AS (
  -- every purchased item (one row per item in a purchase event)
  SELECT
    event_date,                                      --  YYYYMMDD
    SUBSTR(event_date,1,6)            AS ym,        --  YYYYMM (month key)
    user_pseudo_id,
    itm.item_name                       AS item_name,
    IFNULL(itm.quantity,1)              AS qty
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  CROSS JOIN UNNEST(items) AS itm
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'  --  Nov‑20 .. Jan‑21
    AND event_name = 'purchase'
),

tee_buyers AS (       -- users who ever bought the Google Red Speckled Tee
  SELECT DISTINCT user_pseudo_id
  FROM purchased_items
  WHERE item_name = 'Google Red Speckled Tee'
),

other_item_qty AS (   -- quantities of every *other* product bought by those users
  SELECT
    ym,
    item_name,
    SUM(qty) AS total_qty
  FROM purchased_items
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM tee_buyers)
    AND item_name <> 'Google Red Speckled Tee'
  GROUP BY ym,item_name
),

ranked AS (           -- rank products inside each month by quantity
  SELECT
    ym,
    item_name,
    total_qty,
    RANK() OVER (PARTITION BY ym ORDER BY total_qty DESC) AS rnk
  FROM other_item_qty
)

SELECT
  FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m', ym)) AS month,
  item_name,
  total_qty
FROM ranked
WHERE rnk = 1              -- keep the most‑purchased product(s) per month
ORDER BY month;