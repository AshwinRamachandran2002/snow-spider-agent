WITH tee_purchase_events AS (
  SELECT  items
  FROM    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE   event_name = 'purchase'
  AND     EXISTS (
            SELECT 1
            FROM   UNNEST(items) AS t
            WHERE  LOWER(t.item_name) = 'google navy speckled tee'
          )
)
SELECT  itm.item_name     AS co_purchased_item,
        SUM(itm.quantity) AS total_quantity
FROM    tee_purchase_events, UNNEST(items) AS itm
WHERE   LOWER(itm.item_name) <> 'google navy speckled tee'
GROUP BY itm.item_name
ORDER BY total_quantity DESC
LIMIT 1;