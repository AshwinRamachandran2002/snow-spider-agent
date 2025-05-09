-- Most purchased “other” products (and quantities) per month
-- among customers who bought the Google Red Speckled Tee
-- for Nov-2020, Dec-2020, Jan-2021
WITH tee_buyers AS (
  -- Customers who purchased the Google Red Speckled Tee
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS itm
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
    AND LOWER(itm.item_name) = 'google red speckled tee'
),
other_products AS (
  -- All other products those customers bought (same 3-month window)
  SELECT
    SUBSTR(event_date, 1, 6)           AS year_month,
    other.item_name,
    SUM(other.quantity)                AS total_qty
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  JOIN tee_buyers USING (user_pseudo_id)
  CROSS JOIN UNNEST(e.items)           AS other
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND e.event_name = 'purchase'
    AND LOWER(other.item_name) <> 'google red speckled tee'
  GROUP BY year_month, other.item_name
),
ranked AS (
  -- Rank products by quantity within each month
  SELECT
    year_month,
    item_name,
    total_qty,
    ROW_NUMBER() OVER (PARTITION BY year_month ORDER BY total_qty DESC) AS rn
  FROM other_products
)
SELECT
  year_month,
  item_name,
  total_qty
FROM ranked
WHERE rn = 1                -- most-purchased product per month
ORDER BY year_month;