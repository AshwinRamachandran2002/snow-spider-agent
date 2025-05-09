/* Most‑purchased products (other than “Google Red Speckled Tee”)
   bought by the same customers, per month
   – period: 2020‑11‑01 → 2021‑01‑31                              */

WITH red_tee_buyers AS (          -- customers who bought the Red Speckled Tee
    SELECT DISTINCT user_pseudo_id
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
      AND event_name = 'purchase'
      AND EXISTS (
            SELECT 1
            FROM UNNEST(items) AS itm
            WHERE itm.item_name = 'Google Red Speckled Tee'
         )
),

buyers_other_items AS (           -- all their other purchased items
    SELECT
        FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
        itm.item_name                                            AS product,
        SUM(COALESCE(itm.quantity, 0))                           AS total_quantity
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    CROSS JOIN UNNEST(items) AS itm
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
      AND event_name = 'purchase'
      AND user_pseudo_id IN (SELECT user_pseudo_id FROM red_tee_buyers)
      AND itm.item_name <> 'Google Red Speckled Tee'             -- exclude the tee itself
    GROUP BY month, product
)

SELECT *
FROM buyers_other_items
ORDER BY month, total_quantity DESC, product;