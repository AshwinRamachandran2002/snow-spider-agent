/*  Most-purchased “other” products (and their quantities) among every shopper
    who bought a Google Red Speckled Tee, shown month-by-month
    for Nov-2020, Dec-2020 and Jan-2021.                                  */

WITH tee_buyers AS (      -- every user that purchased the Google Red Speckled Tee
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(items) AS it
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
    AND LOWER(it.item_name) LIKE '%google%red%speckled%tee%'
),

monthly_other AS (        -- quantities of ALL OTHER items bought by those users
  SELECT
    CONCAT(SUBSTR(event_date,1,4), '-', SUBSTR(event_date,5,2)) AS month,
    it.item_name                                               AS other_item,
    SUM(it.quantity)                                           AS total_qty
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(items) AS it
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM tee_buyers)
    AND LOWER(it.item_name) NOT LIKE '%google%red%speckled%tee%'
  GROUP BY month, other_item
),

ranked AS (               -- pick the single top-selling OTHER item each month
  SELECT
    month,
    other_item,
    total_qty,
    ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_qty DESC) AS rn
  FROM monthly_other
)

SELECT
  month,
  other_item   AS top_other_product,
  total_qty    AS quantity_sold
FROM ranked
WHERE rn = 1
  AND month IN ('2020-11', '2020-12', '2021-01')   -- keep the required months
ORDER BY month;