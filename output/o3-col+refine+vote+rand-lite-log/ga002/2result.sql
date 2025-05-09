/*  Most purchased “other” products (≠ Google Red Speckled Tee)
    bought by the tee-buyers in each month
    – November-2020, December-2020, January-2021                 */

WITH /* ---------- tee buyers per month ---------- */
tee_buyers AS (
  /* November-2020 */
  SELECT DISTINCT '2020-11' AS month, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`,
       UNNEST(items) AS it
  WHERE event_name = 'purchase'
    AND LOWER(it.item_name) = 'google red speckled tee'

  UNION ALL
  /* December-2020 */
  SELECT DISTINCT '2020-12', user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(items) AS it
  WHERE event_name = 'purchase'
    AND LOWER(it.item_name) = 'google red speckled tee'

  UNION ALL
  /* January-2021 */
  SELECT DISTINCT '2021-01', user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`,
       UNNEST(items) AS it
  WHERE event_name = 'purchase'
    AND LOWER(it.item_name) = 'google red speckled tee'
),

/* ---------- purchases done by those tee buyers (tee excluded) ---------- */
buyers_purchases AS (
  /* November-2020 */
  SELECT '2020-11' AS month,
         i.item_name AS product,
         i.quantity  AS qty
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`  e
  JOIN tee_buyers tb
    ON tb.user_pseudo_id = e.user_pseudo_id
   AND tb.month         = '2020-11'
  CROSS JOIN UNNEST(e.items) AS i
  WHERE e.event_name = 'purchase'
    AND LOWER(i.item_name) <> 'google red speckled tee'

  UNION ALL
  /* December-2020 */
  SELECT '2020-12',
         i.item_name,
         i.quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`  e
  JOIN tee_buyers tb
    ON tb.user_pseudo_id = e.user_pseudo_id
   AND tb.month         = '2020-12'
  CROSS JOIN UNNEST(e.items) AS i
  WHERE e.event_name = 'purchase'
    AND LOWER(i.item_name) <> 'google red speckled tee'

  UNION ALL
  /* January-2021 */
  SELECT '2021-01',
         i.item_name,
         i.quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`  e
  JOIN tee_buyers tb
    ON tb.user_pseudo_id = e.user_pseudo_id
   AND tb.month         = '2021-01'
  CROSS JOIN UNNEST(e.items) AS i
  WHERE e.event_name = 'purchase'
    AND LOWER(i.item_name) <> 'google red speckled tee'
),

/* ---------- aggregate quantities per month & product ---------- */
month_product_totals AS (
  SELECT month,
         product,
         SUM(qty) AS total_qty
  FROM buyers_purchases
  GROUP BY month, product
),

/* ---------- pick the (ties-aware) top product(s) per month ---------- */
ranked AS (
  SELECT month,
         product,
         total_qty,
         DENSE_RANK() OVER (PARTITION BY month ORDER BY total_qty DESC) AS rnk
  FROM month_product_totals
)

SELECT month,
       product,
       total_qty
FROM   ranked
WHERE  rnk = 1          -- most purchased “other” product(s) in the month
ORDER  BY month;