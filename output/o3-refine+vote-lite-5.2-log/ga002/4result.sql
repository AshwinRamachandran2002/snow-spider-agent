-- Most purchased (by quantity) products *other than* “Google Red Speckled Tee”
-- bought by the same customers, per month (Nov‑2020 – Jan‑2021)
WITH tee_buyers AS (          -- 1. Who bought the tee, per month?
  SELECT DISTINCT
         FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS month,
         user_pseudo_id
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
        UNNEST(items) AS itm
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
    AND itm.item_name = 'Google Red Speckled Tee'
),

other_purchases AS (          -- 2. Other products those users bought in the same month
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', e.event_date)) AS month,
    itm.item_name,
    SUM(itm.quantity) AS total_qty
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  JOIN  tee_buyers AS tb
    ON  tb.user_pseudo_id = e.user_pseudo_id
    AND tb.month        = FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', e.event_date))
  CROSS JOIN UNNEST(e.items) AS itm
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND e.event_name = 'purchase'
    AND itm.item_name <> 'Google Red Speckled Tee'
  GROUP BY month, itm.item_name
),

ranked AS (                   -- 3. Rank products within each month by quantity
  SELECT
    month,
    item_name,
    total_qty,
    RANK() OVER (PARTITION BY month ORDER BY total_qty DESC) AS rk
  FROM other_purchases
)

SELECT
  month,
  item_name AS most_purchased_product,
  total_qty AS total_quantity
FROM ranked
WHERE rk = 1                  -- keep only the “most purchased”
ORDER BY month;