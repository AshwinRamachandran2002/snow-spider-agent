/*  Most‑purchased “other” item per month (Nov‑2020 → Jan‑2021) 
    among users who bought the Google Red Speckled Tee           */

WITH tee_buyers AS (
    /*  All months’ buyers of the Tee, labelled by the month
        of the purchase (YYYY‑MM)                                 */
    SELECT DISTINCT
           FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS month,
           user_pseudo_id
    FROM   `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20*`,
           UNNEST(items) AS itm
    WHERE  event_date BETWEEN '20201101' AND '20210131'
      AND  LOWER(itm.item_name) = 'google red speckled tee'
      AND  event_name          = 'purchase'
),

other_items AS (
    /*  All *other* products those same users bought
        in the SAME month                                         */
    SELECT
           tb.month,
           oi.item_name                 AS product,
           SUM(oi.quantity)             AS qty
    FROM   `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20*` ev
    JOIN   tee_buyers tb
      ON   ev.user_pseudo_id = tb.user_pseudo_id
     AND   FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', ev.event_date)) = tb.month
    JOIN   UNNEST(ev.items) AS oi
    WHERE  LOWER(oi.item_name) <> 'google red speckled tee'
      AND  ev.event_name       = 'purchase'
    GROUP BY tb.month, product
)

SELECT
       month,
       product,
       qty
FROM   (
        SELECT
               month,
               product,
               qty,
               ROW_NUMBER() OVER (PARTITION BY month ORDER BY qty DESC) AS rn
        FROM   other_items
)
WHERE  rn = 1
ORDER BY month;