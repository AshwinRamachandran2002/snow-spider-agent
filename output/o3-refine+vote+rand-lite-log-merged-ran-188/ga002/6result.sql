-- Most purchased (non‑Tee) products and their total quantities
-- among customers who bought the “Google Red Speckled Tee”,
-- shown separately for Nov‑2020, Dec‑2020 and Jan‑2021
WITH purchase_items AS (      -- every item bought on a purchase event
  SELECT
    SUBSTR(event_date,1,6)              AS ym,          -- e.g. 202011
    user_pseudo_id,
    LOWER(item.item_name)               AS product_name,
    COALESCE(item.quantity,0)           AS qty
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(items) AS item
  WHERE event_name = 'purchase'
    AND SUBSTR(_TABLE_SUFFIX,1,6) IN ('202011','202012','202101')  -- three months of interest
),

tee_buyers AS (                -- users who bought the Tee in each month
  SELECT DISTINCT ym, user_pseudo_id
  FROM purchase_items
  WHERE product_name = 'google red speckled tee'
),

other_products AS (            -- their other products and quantities
  SELECT
    pi.ym,
    pi.product_name,
    SUM(pi.qty) AS total_qty
  FROM purchase_items AS pi
  JOIN tee_buyers      AS tb
    ON  pi.ym            = tb.ym
    AND pi.user_pseudo_id = tb.user_pseudo_id
  WHERE pi.product_name <> 'google red speckled tee'
  GROUP BY pi.ym, pi.product_name
),

ranked AS (                    -- pick the top‑selling other product per month
  SELECT
    ym,
    product_name,
    total_qty,
    ROW_NUMBER() OVER (PARTITION BY ym
                       ORDER BY total_qty DESC, product_name) AS rn
  FROM other_products
)

SELECT
  ym                                   AS month_yyyymm,
  INITCAP(product_name)                AS most_purchased_product,
  total_qty
FROM ranked
WHERE rn = 1
ORDER BY month_yyyymm;