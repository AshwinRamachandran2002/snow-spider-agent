/*  Most purchased products (excluding the “Google Red Speckled Tee”) bought
    by customers who purchased that tee, broken out by month
    for Nov‑2020, Dec‑2020 and Jan‑2021                                  */

WITH purchases AS (
  SELECT
      event_date,                                    -- YYYYMMDD
      SUBSTR(event_date,1,6)           AS ym,       -- YYYYMM
      user_pseudo_id,
      i.item_name                       AS product_name,
      IFNULL(i.quantity,1)              AS qty
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
        UNNEST(items) AS i
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
    AND i.item_name IS NOT NULL
),

-- customers who bought the Google Red Speckled Tee in each month
red_tee_buyers AS (
  SELECT DISTINCT
         ym,
         user_pseudo_id
  FROM   purchases
  WHERE  LOWER(product_name) = 'google red speckled tee'
),

-- all other products those customers bought in the same month
buyers_purchases AS (
  SELECT
      p.ym,
      p.product_name,
      SUM(p.qty) AS total_qty
  FROM purchases AS p
  JOIN red_tee_buyers AS b
    ON  p.ym = b.ym
   AND p.user_pseudo_id = b.user_pseudo_id
  WHERE LOWER(p.product_name) != 'google red speckled tee'
  GROUP BY p.ym, p.product_name
),

ranked AS (
  SELECT
      ym,
      product_name,
      total_qty,
      ROW_NUMBER() OVER (PARTITION BY ym ORDER BY total_qty DESC, product_name) AS rn
  FROM  buyers_purchases
)

SELECT
    CONCAT(SUBSTR(ym,1,4),'-',SUBSTR(ym,5,2)) AS month,   -- nicer format YYYY-MM
    product_name,
    total_qty
FROM ranked
WHERE rn = 1            -- “most purchased” product(s) each month
ORDER BY month;