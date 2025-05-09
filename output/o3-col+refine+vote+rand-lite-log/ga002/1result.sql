-- Most-purchased “other” products (and their quantities) for customers
-- who bought the Google Red Speckled Tee in Nov-2020, Dec-2020 and Jan-2021
WITH purchases AS (
  SELECT
    CASE
      WHEN _TABLE_SUFFIX LIKE '202011%' THEN '2020-11'
      WHEN _TABLE_SUFFIX LIKE '202012%' THEN '2020-12'
      WHEN _TABLE_SUFFIX LIKE '202101%' THEN '2021-01'
    END                               AS month,
    e.user_pseudo_id,
    item.item_name,
    item.quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  CROSS JOIN UNNEST(e.items) AS item
  WHERE (_TABLE_SUFFIX LIKE '202011%'      -- Nov-2020
         OR _TABLE_SUFFIX LIKE '202012%'   -- Dec-2020
         OR _TABLE_SUFFIX LIKE '202101%')  -- Jan-2021
    AND e.event_name = 'purchase'
),

-- Shoppers who bought the Google Red Speckled Tee in each month
tee_buyers AS (
  SELECT DISTINCT month, user_pseudo_id
  FROM purchases
  WHERE LOWER(item_name) LIKE '%google red speckled tee%'
)

-- Aggregate the other products those shoppers bought
SELECT
  p.month,
  p.item_name,
  SUM(p.quantity) AS total_quantity
FROM purchases AS p
JOIN tee_buyers AS t
  ON p.month = t.month
 AND p.user_pseudo_id = t.user_pseudo_id
WHERE LOWER(p.item_name) NOT LIKE '%google red speckled tee%'
GROUP BY p.month, p.item_name
ORDER BY p.month, total_quantity DESC;