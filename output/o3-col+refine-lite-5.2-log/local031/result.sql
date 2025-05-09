SELECT COUNT(*) AS highest_monthly_delivered_orders
FROM   "olist_orders"
WHERE  "order_status" = 'delivered'
  AND  strftime('%Y‑%m', "order_purchase_timestamp") =
       ( /* month with the highest volume inside the lowest‑volume year */
         SELECT strftime('%Y‑%m', "order_purchase_timestamp")
         FROM   "olist_orders"
         WHERE  "order_status" = 'delivered'
           AND  strftime('%Y', "order_purchase_timestamp") =
                ( /* year with the lowest annual volume (2016‑2018) */
                  SELECT strftime('%Y', "order_purchase_timestamp")
                  FROM   "olist_orders"
                  WHERE  "order_status" = 'delivered'
                    AND  strftime('%Y', "order_purchase_timestamp") IN ('2016','2017','2018')
                  GROUP  BY strftime('%Y', "order_purchase_timestamp")
                  ORDER  BY COUNT(*) ASC
                  LIMIT 1
                )
         GROUP  BY strftime('%Y‑%m', "order_purchase_timestamp")
         ORDER  BY COUNT(*) DESC
         LIMIT 1
       );