WITH tee_buyers AS (   -- users that bought “Google Red Speckled Tee” each month
  SELECT DISTINCT
         user_pseudo_id,
         SUBSTR(event_date,1,6) AS ym               -- YYYYMM
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(items) AS itm
  WHERE (_TABLE_SUFFIX LIKE '202011%' OR              -- Nov‑2020
         _TABLE_SUFFIX LIKE '202012%' OR              -- Dec‑2020
         _TABLE_SUFFIX LIKE '202101%')                -- Jan‑2021
    AND event_name = 'purchase'
    AND itm.item_name = 'Google Red Speckled Tee'
    AND IFNULL(itm.quantity,0) > 0
),

other_purchases AS (   -- all OTHER products bought by those users in the same month
  SELECT
    SUBSTR(e.event_date,1,6) AS ym,
    itm.item_name,
    SUM(IFNULL(itm.quantity,0)) AS total_quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`  e
  JOIN tee_buyers t
    ON t.user_pseudo_id = e.user_pseudo_id
   AND t.ym            = SUBSTR(e.event_date,1,6)
  CROSS JOIN UNNEST(e.items) AS itm
  WHERE (e._TABLE_SUFFIX LIKE '202011%' OR
         e._TABLE_SUFFIX LIKE '202012%' OR
         e._TABLE_SUFFIX LIKE '202101%')
    AND e.event_name = 'purchase'
    AND itm.item_name <> 'Google Red Speckled Tee'
    AND IFNULL(itm.quantity,0) > 0
  GROUP BY ym, itm.item_name
),

ranked AS (           -- pick the most‑purchased product each month
  SELECT
    ym,
    item_name,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY ym
                       ORDER BY total_quantity DESC, item_name) AS rn
  FROM other_purchases
)

SELECT
  ym          AS month,          -- YYYYMM
  item_name   AS most_purchased_item,
  total_quantity
FROM ranked
WHERE rn = 1
ORDER BY month;