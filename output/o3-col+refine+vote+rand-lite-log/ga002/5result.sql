/*  Most-purchased “other products” (and their quantities)
    bought by customers who purchased the “Google Red Speckled Tee”
    in each month Nov-2020, Dec-2020, Jan-2021                      */

WITH monthly_events AS (
  SELECT
    CASE SUBSTR(_TABLE_SUFFIX,1,6)
         WHEN '202011' THEN '2020-11'
         WHEN '202012' THEN '2020-12'
         WHEN '202101' THEN '2021-01'
    END                         AS month,
    user_pseudo_id,
    event_name,
    items
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND SUBSTR(_TABLE_SUFFIX,1,6) IN ('202011','202012','202101')
),

-- shoppers who bought the Google Red Speckled Tee in the given month
tee_buyers AS (
  SELECT DISTINCT
         month,
         user_pseudo_id
  FROM   monthly_events, UNNEST(items) AS it
  WHERE  event_name = 'purchase'
    AND  LOWER(it.item_name) LIKE '%google red speckled tee%'
),

-- their OTHER products purchased in the same month
other_products AS (
  SELECT
    me.month,
    it.item_name,
    SUM(it.quantity) AS total_qty
  FROM   monthly_events AS me
  JOIN   tee_buyers    AS tb
         ON  tb.month = me.month
         AND tb.user_pseudo_id = me.user_pseudo_id
  CROSS JOIN UNNEST(me.items) AS it
  WHERE  me.event_name = 'purchase'
    AND  LOWER(it.item_name) NOT LIKE '%google red speckled tee%'
  GROUP BY me.month, it.item_name
),

ranked AS (
  SELECT
    month,
    item_name,
    total_qty,
    ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_qty DESC) AS rn
  FROM   other_products
)

SELECT
  month,
  item_name  AS most_purchased_other_product,
  total_qty
FROM   ranked
WHERE  rn = 1
ORDER BY month;