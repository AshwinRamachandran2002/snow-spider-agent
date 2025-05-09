-- Most purchased “other” products (and their quantities) 
-- among customers who bought the Google Red Speckled Tee,
-- for each month Nov-2020, Dec-2020 and Jan-2021
WITH tee_buyers AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e,
       UNNEST(e.items) AS it
  WHERE e.event_name = 'purchase'
    AND LOWER(it.item_name) LIKE '%google red speckled tee%'
    AND _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'          -- Nov-2020 → Jan-2021
),
other_products AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
    it.item_name                                             AS product,
    SUM(it.quantity)                                         AS total_qty
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
  JOIN UNNEST(e.items) AS it
  ON TRUE
  WHERE e.event_name = 'purchase'
    AND _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND e.user_pseudo_id IN (SELECT user_pseudo_id FROM tee_buyers)
    AND LOWER(it.item_name) NOT LIKE '%google red speckled tee%' -- exclude the tee itself
  GROUP BY month, product
),
ranked AS (
  SELECT
    month,
    product,
    total_qty,
    ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_qty DESC) AS rn
  FROM other_products
)
SELECT
  month,
  product  AS most_purchased_product,
  total_qty AS quantity
FROM ranked
WHERE rn = 1
ORDER BY month;