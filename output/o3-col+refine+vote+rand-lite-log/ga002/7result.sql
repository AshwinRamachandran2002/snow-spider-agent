/*  Most-purchased OTHER product (and its total quantity) for customers who
    bought the Google Red Speckled Tee in each month: 2020-11, 2020-12, 2021-01 */

WITH base AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
    user_pseudo_id,
    LOWER(item.item_name)            AS item_name_lc,
    item.item_name                   AS item_name,
    item.quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
),

tee_buyers AS (                       -- users who bought the Tee in each month
  SELECT DISTINCT month, user_pseudo_id
  FROM base
  WHERE item_name_lc = 'google red speckled tee'
),

other_products AS (                   -- other products those users bought
  SELECT
    b.month,
    b.item_name,
    SUM(b.quantity) AS total_qty
  FROM base AS b
  JOIN tee_buyers AS t
    ON  b.month = t.month
   AND b.user_pseudo_id = t.user_pseudo_id
  WHERE b.item_name_lc <> 'google red speckled tee'
  GROUP BY b.month, b.item_name
),

ranked AS (                           -- pick the top-selling product per month
  SELECT
    month,
    item_name,
    total_qty,
    ROW_NUMBER() OVER (PARTITION BY month
                       ORDER BY total_qty DESC, item_name) AS rn
  FROM other_products
)

SELECT
  month,
  item_name  AS most_purchased_other_product,
  total_qty
FROM ranked
WHERE rn = 1
ORDER BY month;