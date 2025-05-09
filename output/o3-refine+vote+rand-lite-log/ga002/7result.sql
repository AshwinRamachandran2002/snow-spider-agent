-- Most‑purchased (non‑Tee) products bought by users who purchased
-- “Google Red Speckled Tee”, per month (Nov‑2020 to Jan‑2021)

WITH tee_buyers AS (       -- users who bought the Tee in each month
  SELECT DISTINCT
         FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS month,
         user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE SUBSTR(event_date,1,6) IN ('202011','202012','202101')
        AND event_name = 'purchase'
        AND EXISTS (SELECT 1
                    FROM UNNEST(items) itm
                    WHERE itm.item_name = 'Google Red Speckled Tee')
),

other_purchases AS (       -- other items those users bought in the same month
  SELECT
        FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', e.event_date)) AS month,
        itm.item_name,
        SUM(itm.quantity) AS total_qty
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
  JOIN tee_buyers tb
       ON tb.user_pseudo_id = e.user_pseudo_id
          AND tb.month = FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', e.event_date))
  CROSS JOIN UNNEST(e.items) AS itm
  WHERE SUBSTR(e.event_date,1,6) IN ('202011','202012','202101')
        AND e.event_name = 'purchase'
        AND itm.item_name != 'Google Red Speckled Tee'          -- exclude the Tee itself
  GROUP BY month, itm.item_name
),

ranked AS (                -- pick the top‑quantity product each month
  SELECT
        month,
        item_name,
        total_qty,
        ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_qty DESC) AS rn
  FROM other_purchases
)

SELECT
      month,
      item_name  AS most_purchased_product,
      total_qty  AS quantity
FROM ranked
WHERE rn = 1
ORDER BY month;