SELECT MAX(monthly_cnt) AS highest_monthly_volume
FROM (
    /* monthly delivered-order counts inside the lowest-volume year (2016-2018) */
    SELECT substr("order_purchase_timestamp",1,7) AS year_month,
           COUNT(*)                               AS monthly_cnt
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
      AND  substr("order_purchase_timestamp",1,4) = (
              /* year (2016-2018) with the fewest delivered orders */
              SELECT substr("order_purchase_timestamp",1,4)
              FROM   "olist_orders"
              WHERE  "order_status" = 'delivered'
                AND  substr("order_purchase_timestamp",1,4) IN ('2016','2017','2018')
              GROUP  BY substr("order_purchase_timestamp",1,4)
              ORDER  BY COUNT(*) ASC
              LIMIT 1
           )
    GROUP  BY substr("order_purchase_timestamp",1,7)
);